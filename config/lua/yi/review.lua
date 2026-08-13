-- in-code review "plugin" loosely based on our previous review ideas "in git" and
-- https://tigerbeetle.com/blog/2025-08-04-code-review-can-be-better/
--
-- TODO use something like https://github.com/Gabriella439/semantic-navigator for semantic "closeness"
-- TODO maybe something that offers per commit review or at least does not require you to squash everything first
-- TODO still not sure how to annotate review comments and collect them (commit?) but also not part of this plugin
-- TODO do we use a small llm to summarise changes? for now just show a bit of "context" extracted heuristically
--      from treesitter (lsp would be nice, but probably not so easy with scratch buffers?)

local M = {}

-- keyed by "file|label", persists across re-invocations within the session
---@type table<string, boolean>
local reviewed = {}

---@class yi.review.Hunk
---@field start_line integer 1-indexed, from the new (right-side) file
---@field end_line integer 1-indexed, from the new (right-side) file
---@field lines string[] raw diff lines, for preview rendering

-- parse unified diff output into Hunks
---@param diff_text string
---@return table<string, yi.review.Hunk[]>
local function parse_diff(diff_text)
    local changes = {}
    ---@type string?
    local current_file = nil
    ---@type yi.review.Hunk?
    local current_hunk = nil
    for line in vim.gsplit(diff_text, "\n") do
        if line:match("^%+%+%+ b/") then
            current_file = line:match("^%+%+%+ b/(.+)$")
            changes[current_file] = changes[current_file] or {}
            current_hunk = nil
        elseif line:match("^diff ") or line:match("^--- ") or line:match("^index ") then
            current_hunk = nil
        elseif current_file then
            -- @@ -old_start[,old_count] +new_start[,new_count] @@
            local s, c = line:match("^@@ %-[%d,]+ %+(%d+),?(%d*) @@")
            if s then
                local start = tonumber(s)
                local count = (c ~= "" and tonumber(c)) or 1
                if count > 0 then
                    ---@cast start integer
                    ---@cast count integer
                    current_hunk = { start_line = start, end_line = start + count - 1, lines = { line } }
                    table.insert(changes[current_file], current_hunk)
                else
                    current_hunk = nil
                end
            elseif current_hunk then
                table.insert(current_hunk.lines, line)
            end
        end
    end
    return changes
end

---@param node TSNode
---@param bufnr integer
---@return string
local function node_text(node, bufnr)
    return vim.treesitter.get_node_text(node, bufnr)
end

---@class yi.review.FunctionAtLine
---@field label string
---@field line number 1-indexed

---@param bufnr integer
---@param line_nr integer 1-indexed
---@return yi.review.FunctionAtLine?
local function get_function_at_line(bufnr, line_nr)
    local ts = require("yi.treesitter")

    local node = vim.treesitter.get_node {
        bufnr = bufnr,
        pos = { line_nr - 1, 0 },
    }
    if not node then
        return nil
    end

    ---@type TSNode?, TSNode?
    local fn_node, class_node = nil, nil
    for ancestor in ts.matching_ancestors(node, { "function", "method", "class", "impl_item", "mod_item" }) do
        local ntype = ancestor:type()
        if not fn_node and (ntype:find("function", 1, true) or ntype:find("method", 1, true)) then
            fn_node = ancestor
        elseif fn_node and not class_node then
            if ntype:find("class", 1, true) or ntype == "impl_item" or ntype == "mod_item" then
                class_node = ancestor
                break
            end
        end
    end

    if not fn_node then
        return nil
    end

    local name_node = fn_node:field("name")[1]
    if not name_node then
        return nil
    end
    local fn_name = node_text(name_node, bufnr)

    local label = fn_name
    if class_node then
        local class_name_node = class_node:field("name")[1] or class_node:field("type")[1]
        if class_name_node then
            label = node_text(class_name_node, bufnr) .. "." .. fn_name
        end
    end

    return { label = label, line = fn_node:start() + 1 }
end

---@class yi.review.ParsedBuffer
---@field bufnr integer
---@field scratch boolean loaded off-screen for this call, must be cleaned up by the caller
---@field root TSNode

-- parses `full_path` for treesitter queries
---@param full_path string
---@return yi.review.ParsedBuffer?
local function open_and_parse(full_path)
    if vim.fn.filereadable(full_path) == 0 then
        return nil
    end

    local bufnr = vim.fn.bufnr(full_path)
    local scratch = bufnr == -1
    if scratch then
        bufnr = vim.fn.bufadd(full_path)
        vim.fn.bufload(bufnr)
    end

    local function fail()
        if scratch then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
        return nil
    end

    local ft = vim.filetype.match { filename = full_path } or vim.bo[bufnr].filetype or ""
    local get_lang = vim.treesitter.language.get_lang
    local lang = (get_lang and get_lang(ft)) or ft
    if lang == "" then
        return fail()
    end

    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not ok or parser == nil then
        return fail()
    end

    local trees = parser:parse()
    if not trees then
        return fail()
    end

    return { bufnr = bufnr, scratch = scratch, root = trees[1]:root() }
end

---@class yi.review.ChangedFunction
---@field label string
---@field file string
---@field line number 1-indexed
---@field diff_lines string[]

---@param pb yi.review.ParsedBuffer
---@param full_path string
---@param ranges yi.review.Hunk[]
---@return yi.review.ChangedFunction[]
local function find_changed_functions(pb, full_path, ranges)
    ---@type table<string, yi.review.ChangedFunction>
    local entries = {}
    ---@type table<string, boolean>
    local hunk_added = {}
    ---@type yi.review.ChangedFunction[]
    local results = {}

    for _, range in ipairs(ranges) do
        for line_nr = range.start_line, range.end_line do
            local fn = get_function_at_line(pb.bufnr, line_nr)
            if fn then
                local key = full_path .. "|" .. fn.label .. "|" .. fn.line
                if not entries[key] then
                    entries[key] = { label = fn.label, file = full_path, line = fn.line, diff_lines = {} }
                    table.insert(results, entries[key])
                end
                local hunk_key = key .. "|" .. tostring(range.start_line)
                if not hunk_added[hunk_key] then
                    hunk_added[hunk_key] = true
                    for _, l in ipairs(range.lines or {}) do
                        table.insert(entries[key].diff_lines, l)
                    end
                end
            end
        end
    end

    return results
end

local max_related_text_length = 80

-- collapses a nodes text into a single readable line
---@param node TSNode
---@param bufnr integer
---@return string
local function node_text_one_line(node, bufnr)
    local text = node_text(node, bufnr):gsub("%s+", " ")
    if #text > max_related_text_length then
        text = text:sub(1, max_related_text_length - 1) .. "\u{2026}"
    end
    return text
end

-- heuristic to find related calls - currently based on textual name match via treesitter
---@class yi.review.RelatedCall
---@field filepath string
---@field line number 1-indexed
---@field enclosing string? label of the function the call site is inside, if any
---@field text string full call expression, collapsed to one line

---@param bare_name string
---@param changes table<string, yi.review.Hunk[]>
---@param parsed_buffers table<string, yi.review.ParsedBuffer|false>
---@return yi.review.RelatedCall[]
local function find_related_calls(bare_name, changes, parsed_buffers)
    local ts = require("yi.treesitter")
    ---@type yi.review.RelatedCall[]
    local related = {}

    for filepath, ranges in pairs(changes) do
        local pb = parsed_buffers[filepath]
        if pb then
            for _, call_node in ipairs(ts.find_calls(pb.bufnr, pb.root, bare_name)) do
                local line = call_node:start() + 1
                for _, range in ipairs(ranges) do
                    if line >= range.start_line and line <= range.end_line then
                        local enclosing = get_function_at_line(pb.bufnr, line)
                        table.insert(related, {
                            filepath = filepath,
                            line = line,
                            enclosing = enclosing and enclosing.label or nil,
                            text = node_text_one_line(call_node, pb.bufnr),
                        })
                        break
                    end
                end
            end
        end
    end

    return related
end

---@class yi.review.PickerItem
---@field text string
---@field label string
---@field filepath string
---@field file string
---@field pos [number, number]
---@field diff_lines string[]
---@field related yi.review.RelatedCall[]
---@field review_key string

---@return string? root
---@return string? diff_text
---@return string? err
local function get_diff()
    local vcs = require("yi.vcs")

    local jj_root = vcs.jj_root()
    if jj_root then
        local diff, diff_ok = vcs.shell("jj diff --git 2>&1")
        if not diff_ok then
            return nil, nil, "jj diff: " .. diff
        end
        return jj_root, diff, nil
    end

    local git_root = vcs.git_root()
    if git_root then
        local diff, diff_ok = vcs.shell("git diff HEAD 2>&1")
        if not diff_ok then
            return nil, nil, "git diff: " .. diff
        end
        return git_root, diff, nil
    end

    return nil, nil, "not inside a jj or git repository"
end

function M.pick_changed_functions()
    local root, diff, err = get_diff()
    if err then
        vim.notify(err, vim.log.levels.ERROR)
        return
    end
    if diff == nil and diff == "" then
        return
    end
    ---@cast diff string

    local changes = parse_diff(diff)

    -- `false` marks a file that failed to parse
    ---@type table<string, yi.review.ParsedBuffer|false>
    local parsed_buffers = {}
    for filepath in pairs(changes) do
        parsed_buffers[filepath] = open_and_parse(root .. "/" .. filepath) or false
    end

    ---@type yi.review.PickerItem[]
    local items = {}
    ---@type table<string, boolean>
    local seen = {}

    for filepath, ranges in pairs(changes) do
        local pb = parsed_buffers[filepath]
        if pb then
            for _, fn in ipairs(find_changed_functions(pb, root .. "/" .. filepath, ranges)) do
                local key = fn.file .. "|" .. fn.label
                if seen[key] then
                    goto continue
                end
                seen[key] = true
                table.insert(items, {
                    text = string.format("%-45s  %s", fn.label, filepath),
                    label = fn.label,
                    filepath = filepath,
                    file = fn.file,
                    pos = { fn.line, 0 },
                    diff_lines = fn.diff_lines,
                    related = {},
                    review_key = key,
                })
                ::continue::
            end
        end
    end

    for _, item in ipairs(items) do
        local bare_name = item.label:match("([^.]+)$") or item.label
        item.related = find_related_calls(bare_name, changes, parsed_buffers)
    end

    for _, pb in pairs(parsed_buffers) do
        if pb and pb.scratch then
            vim.api.nvim_buf_delete(pb.bufnr, { force = true })
        end
    end

    table.sort(items, function(a, b)
        ---@type boolean, boolean
        local a_reviewed, b_reviewed = reviewed[a.review_key] or false, reviewed[b.review_key] or false
        if a_reviewed ~= b_reviewed then
            -- layouts render with reverse = true, so index 1 is the bottom row on screen
            return not a_reviewed
        end
        return a.text < b.text
    end)

    -- TODO return or show empty picker?
    -- if #items == 0 then
    --     return
    -- end
    require("snacks.picker").pick {
        title = "changed functions (" .. #items .. ")",
        items = items,
        format = function(item, _)
            local icon_hl = reviewed[item.review_key] and "DiagnosticOk" or "SnacksPickerComment"
            return {
                { reviewed[item.review_key] and "\u{f00c} " or "  ", icon_hl },
                { string.format("%-45s  %s", item.label, item.filepath) },
            }
        end,
        preview = function(ctx)
            ---@type string[]
            local lines = {}
            local related = ctx.item.related or {}
            if #related > 0 then
                table.insert(lines, "-- Related changed call sites:")
                for _, rel in ipairs(related) do
                    local where = rel.enclosing and (" (in " .. rel.enclosing .. ")") or ""
                    table.insert(lines, string.format("--   %s:%d%s", rel.filepath, rel.line, where))
                    table.insert(lines, "--     " .. rel.text)
                end
                table.insert(lines, "")
            end
            vim.list_extend(lines, ctx.item.diff_lines or {})
            vim.bo[ctx.buf].modifiable = true
            vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
            vim.bo[ctx.buf].filetype = "diff"
        end,
        confirm = function(picker, item, action)
            reviewed[item.review_key] = true
            require("snacks.picker.actions").jump(picker, item, action)
        end,
    }
end

return M
