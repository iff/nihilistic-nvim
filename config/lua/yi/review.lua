local M = {}

-- Parse unified diff output into {filepath: [{start_line, end_line, lines}]}
-- Line numbers are 1-indexed, from the new (right-side) file.
-- Each hunk entry carries the raw diff lines for preview rendering.
local function parse_diff(diff_text)
    local changes = {}
    local current_file = nil
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
                    current_hunk = { start, start + count - 1, lines = { line } }
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

local ts = require("yi.treesitter")

local function node_text(node, bufnr)
    return vim.treesitter.get_node_text(node, bufnr)
end

local function get_function_at_line(bufnr, line_nr)
    local node = vim.treesitter.get_node { bufnr = bufnr, pos = { line_nr - 1, 0 } }
    if not node then
        return nil
    end

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

local function find_changed_functions(filepath, ranges, root)
    local full_path = root .. "/" .. filepath
    if vim.fn.filereadable(full_path) == 0 then
        return {}
    end

    local bufnr = vim.fn.bufnr(full_path)
    local scratch = bufnr == -1
    if scratch then
        bufnr = vim.fn.bufadd(full_path)
        vim.fn.bufload(bufnr)
    end

    local ft = vim.filetype.match { filename = full_path } or vim.bo[bufnr].filetype or ""
    local get_lang = vim.treesitter.language.get_lang
    local lang = (get_lang and get_lang(ft)) or ft
    if lang == "" then
        if scratch then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
        return {}
    end

    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not ok or parser == nil then
        if scratch then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
        return {}
    end
    parser:parse()

    local entries = {}
    local hunk_added = {}
    local results = {}

    for _, range in ipairs(ranges) do
        for line_nr = range[1], range[2] do
            local fn = get_function_at_line(bufnr, line_nr)
            if fn then
                local key = full_path .. "|" .. fn.label .. "|" .. fn.line
                if not entries[key] then
                    entries[key] = { label = fn.label, file = full_path, line = fn.line, diff_lines = {} }
                    table.insert(results, entries[key])
                end
                local hunk_key = key .. "|" .. tostring(range[1])
                if not hunk_added[hunk_key] then
                    hunk_added[hunk_key] = true
                    for _, l in ipairs(range.lines or {}) do
                        table.insert(entries[key].diff_lines, l)
                    end
                end
            end
        end
    end

    if scratch then
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    return results
end

function M.pick_changed_functions()
    -- TODO only jj for now
    -- TODO is there a better way to get hunks without "git/jj diff"?
    local root = vim.fn.system("jj workspace root 2>/dev/null"):gsub("\n$", "")
    if root == "" then
        root = vim.fn.getcwd()
    end

    local diff = vim.fn.system("jj diff --git 2>&1")
    if vim.v.shell_error ~= 0 then
        vim.notify("jj diff: " .. diff, vim.log.levels.ERROR)
        return
    end
    if diff == "" then
        return
    end

    local changes = parse_diff(diff)
    local items = {}
    local seen = {}

    for filepath, ranges in pairs(changes) do
        for _, fn in ipairs(find_changed_functions(filepath, ranges, root)) do
            local key = fn.file .. "|" .. fn.label
            if seen[key] then
                goto continue
            end
            seen[key] = true
            table.insert(items, {
                text = string.format("%-45s  %s", fn.label, filepath),
                file = fn.file,
                pos = { fn.line, 0 },
                diff_lines = fn.diff_lines,
            })
            ::continue::
        end
    end

    table.sort(items, function(a, b)
        return a.text < b.text
    end)

    -- TODO return or show empty picker?
    -- if #items == 0 then
    --     return
    -- end

    require("snacks.picker").pick {
        title = "changed functions (" .. #items .. ")",
        items = items,
        preview = function(ctx)
            local lines = ctx.item.diff_lines or {}
            vim.bo[ctx.buf].modifiable = true
            vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
            vim.bo[ctx.buf].filetype = "diff"
        end,
    }
end

return M
