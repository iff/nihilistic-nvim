local M = {}

-- markdown notes in ~/src/notes with format "<id>-<slug>.md"
local notes_dir = vim.fn.expand("~/src/notes")
local hl_group = "NotesWikiLink"

---@return string[] absolute paths of every note
local function note_files()
    -- TODO cheap enough for now, needs a cache eventually (?)
    return vim.fn.globpath(notes_dir, "*.md", false, true)
end

---@param path string
---@return string basename with the leading id stripped
local function slug_of(path)
    local base = vim.fn.fnamemodify(path, ":t:r")
    return (base:gsub("^%d+[-_]", ""))
end

---@param name string
---@return boolean whether name lives under notes_dir
local function in_notes_dir(name)
    if name == "" then
        return false
    end
    local root = vim.fs.normalize(notes_dir)
    return vim.fs.normalize(name):find(root, 1, true) == 1
end

--- Resolve a link target to candidate files, most-specific bucket first.
--- Loose matching keeps links short while the convention is still sparse;
--- ambiguity is pushed to a picker rather than guessed.
---@param target string
---@return string[]
local function resolve(target)
    target = vim.trim(target):lower()
    local exact, by_slug, loose = {}, {}, {}
    for _, path in ipairs(note_files()) do
        local base = vim.fn.fnamemodify(path, ":t:r"):lower()
        if base == target then
            table.insert(exact, path)
        elseif slug_of(path):lower() == target then
            table.insert(by_slug, path)
        elseif base:find(target, 1, true) then
            table.insert(loose, path)
        end
    end
    if #exact > 0 then
        return exact
    end
    if #by_slug > 0 then
        return by_slug
    end
    return loose
end

---@param path string
local function edit(path)
    vim.cmd.edit(vim.fn.fnameescape(path))
end

---@param title string
---@param paths string[]
local function pick_paths(title, paths)
    require("snacks.picker").pick {
        title = title,
        items = vim.tbl_map(function(path)
            return { text = vim.fn.fnamemodify(path, ":t"), file = path }
        end, paths),
        format = "file",
        confirm = function(picker, item)
            picker:close()
            edit(item.file)
        end,
    }
end

---@param target string
local function create(target)
    local slug = target:lower():gsub("%s+", "-"):gsub("[^%w%-_]", "")
    local name = os.date("%Y%m%d%H%M") .. "-" .. slug .. ".md"
    local path = notes_dir .. "/" .. name
    if vim.fn.confirm(("no note for [[%s]] -- create %s?"):format(target, name), "&yes\n&no", 2) == 1 then
        edit(path)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# " .. target, "" })
    end
end

---@param target string
function M.open(target)
    local hits = resolve(target)
    if #hits == 0 then
        create(target)
    elseif #hits == 1 then
        edit(hits[1])
    else
        pick_paths("resolve [[" .. target .. "]]", hits)
    end
end

--- follow the [[wikilink]] under the cursor (gf-style).
function M.follow()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local from = 1
    while true do
        local s, e, target = line:find("%[%[([^%]|]+)|?[^%]]*%]%]", from)
        if not s then
            break
        end
        if col >= s - 1 and col <= e then
            return M.open(vim.trim(target))
        end
        from = e + 1
    end
    vim.notify("no wikilink under cursor", vim.log.levels.WARN)
end

--- snacks picker of every [[link]] pointing at the current note.
function M.pick_backlinks()
    local buf_path = vim.api.nvim_buf_get_name(0)
    assert(in_notes_dir(buf_path), "not a note buffer")

    local base = vim.fn.fnamemodify(buf_path, ":t:r")
    -- a note can be referenced by full basename, by slug, or by bare id
    local names = { base, slug_of(buf_path), base:match("^(%d+)") or "" }

    local seen, alternatives = {}, {}
    for _, name in ipairs(names) do
        if name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(alternatives, vim.fn.escape(name, [==[\.^$*+?()[]{}|/]==]))
        end
    end

    local pattern = ([==[\[\[\s*(%s)\s*(\|[^\]]*)?\]\]]==]):format(table.concat(alternatives, "|"))
    local result = vim.system(
        { "rg", "--vimgrep", "--color=never", "--no-heading", "-e", pattern, notes_dir },
        { text = true }
    )
        :wait()

    local items = {}
    for _, raw in ipairs(vim.split(result.stdout or "", "\n", { trimempty = true })) do
        local file, lnum, cnum, text = raw:match("^(.-):(%d+):(%d+):(.*)$")
        if file and file ~= buf_path then
            table.insert(items, {
                text = vim.fn.fnamemodify(file, ":t") .. "  " .. text,
                file = file,
                pos = { tonumber(lnum), tonumber(cnum) - 1 },
            })
        end
    end

    if #items == 0 then
        return vim.notify("no backlinks to " .. base, vim.log.levels.INFO)
    end

    require("snacks.picker").pick {
        title = "backlinks: " .. base,
        items = items,
        format = "file",
        confirm = function(picker, item)
            picker:close()
            edit(item.file)
            vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
        end,
    }
end

--- blink.cmp source: complete note names inside an open "[[".
local source = {}
source.__index = source

function source.new()
    return setmetatable({}, source)
end

function source:enabled()
    return in_notes_dir(vim.api.nvim_buf_get_name(0))
end

function source:get_trigger_characters()
    return { "[" }
end

function source:get_completions(ctx, callback)
    local typed = ctx.line:sub(1, ctx.cursor[2]):match("%[%[([^%]]*)$")
    if not typed then
        return callback { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }
    end

    local kind = require("blink.cmp.types").CompletionItemKind.Reference
    local start_col = ctx.cursor[2] - #typed
    local items = vim.tbl_map(function(path)
        local base = vim.fn.fnamemodify(path, ":t:r")
        return {
            label = base,
            filterText = base .. " " .. slug_of(path),
            kind = kind,
            -- assumes the closing "]]" was not pre-typed
            textEdit = {
                newText = base .. "]]",
                range = {
                    start = { line = ctx.cursor[1] - 1, character = start_col },
                    ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
                },
            },
        }
    end, note_files())

    callback { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
end

M.blink_source = source

-- blink instantiates the provider via require("yi.notes").new()
M.new = source.new

function M.setup()
    vim.api.nvim_set_hl(0, hl_group, { link = "@markup.link.label", default = true })

    local group = vim.api.nvim_create_augroup("yi_notes", { clear = true })

    -- treesitter-markdown emits no node for [[...]], so decorate with matchadd (per window)
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
        group = group,
        pattern = notes_dir .. "/*.md",
        callback = function()
            if vim.w.yi_notes_hl then
                return
            end
            vim.w.yi_notes_hl = true
            vim.fn.matchadd(hl_group, [==[\[\[[^\]]\+\]\]]==])
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function(args)
            if not in_notes_dir(vim.api.nvim_buf_get_name(args.buf)) then
                return
            end
            vim.keymap.set("n", "gf", M.follow, { buffer = args.buf, desc = "follow wikilink" })
            vim.keymap.set("n", "<c-]>", M.follow, { buffer = args.buf, desc = "follow wikilink" })
        end,
    })
end

return M
