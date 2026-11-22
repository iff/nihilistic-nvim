-- draw indent guides using treesitter `folds` queries only for the currently visible rows.
-- NOTE using unstable `api.nvim__redraw`, but used like this in Neovim's own treesitter highlighter

local api = vim.api
local ts = vim.treesitter

local M = {}

local ns = api.nvim_create_namespace("yi.indent_guides")
local augroup = api.nvim_create_augroup("yi.indent_guides", { clear = true })

local GUIDE_CHAR = "│"

--- buffers with guides enabled, either "idle", or
--- "parsing": a parse has been started in the background for this buffer and callback hasn't run
---@type table<integer, ("idle"|"parsing")?>
local enabled = {}

--- compute display width of `line`s leading whitespace
---@param tabstop integer the buffer's 'tabstop'
---@param line string
---@return integer width
---@return boolean blank whether the line contains only whitespace
local function leading_width(tabstop, line)
    local width = 0
    local index = 1
    local length = #line
    while index <= length do
        local byte = line:byte(index)
        if byte == 32 then
            width = width + 1
        elseif byte == 9 then
            -- currently dont support 'vartabstop': tabs always advance to the next multiple of tabstop
            width = width + tabstop - width % tabstop
        else
            return width, false
        end
        index = index + 1
    end
    return width, true
end

--- collects guide columns per row for rows in current view [`top_row`, `bottom_row`].
---@param buf integer
---@param parser vim.treesitter.LanguageTree
---@param tabstop integer the buffer's 'tabstop'
---@param top_row integer
---@param bottom_row integer
---@return table<integer, table<integer, true>> guides_by_row set of guide columns per row
local function collect_guides(buf, parser, tabstop, top_row, bottom_row)
    local guides_by_row = {} ---@type table<integer, table<integer, true>>
    local indent_cache = {} ---@type table<integer, integer>

    ---@param row integer
    ---@return integer
    local function row_indent(row)
        local width = indent_cache[row]
        if not width then
            local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
            width = leading_width(tabstop, line)
            indent_cache[row] = width
        end
        return width
    end

    --- guide for one `@fold` capture to the visible rows it spans below its first line
    ---@param nodes TSNode[] more than one for quantified captures, e.g. `(use_declaration)+`
    ---@param metadata? vim.treesitter.query.TSMetadata
    local function add_fold(nodes, metadata)
        local first_node, last_node = nodes[1], nodes[#nodes]
        if not first_node or not last_node then
            return
        end
        local start_row = ts.get_range(first_node, buf, metadata)[1]
        local _, _, _, end_row, end_col = unpack(ts.get_range(last_node, buf, metadata))
        -- a range ending at column 0 only includes the previous line's newline
        if end_col == 0 then
            end_row = end_row - 1
        end

        local first_row = math.max(start_row + 1, top_row)
        local last_row = math.min(end_row, bottom_row)
        if first_row > last_row then
            return
        end

        local column = row_indent(start_row)
        for row = first_row, last_row do
            local columns = guides_by_row[row]
            if not columns then
                columns = {}
                guides_by_row[row] = columns
            end
            columns[column] = true
        end
    end

    parser:for_each_tree(function(tree, language_tree)
        local query = ts.query.get(language_tree:lang(), "folds")
        if not query then
            return
        end

        for _, match, metadata in query:iter_matches(tree:root(), buf, top_row, bottom_row + 1) do
            for id, nodes in pairs(match) do
                if query.captures[id] == "fold" then
                    add_fold(nodes, metadata[id])
                end
            end
        end
    end)

    return guides_by_row
end

---@param buf integer
---@param parser vim.treesitter.LanguageTree
---@param range Range2
local function ensure_parsed(buf, parser, range)
    if enabled[buf] == "parsing" or parser:is_valid(false, { range[1], 0, range[2], 0 }) then
        return
    end
    enabled[buf] = "parsing"
    parser:parse(range, function(err)
        if not enabled[buf] then
            return
        end
        enabled[buf] = "idle"
        -- dont retrigger parse on err (timeout)
        if not err and api.nvim_buf_is_valid(buf) then
            api.nvim__redraw { buf = buf, valid = false, flush = false }
        end
    end)
end

---@param win integer
---@param buf integer
---@param top_row integer
---@param bottom_row integer
---@return boolean
local function on_win(_, win, buf, top_row, bottom_row)
    if not enabled[buf] then
        return false
    end

    local parser = ts.get_parser(buf, nil, { error = false })
    if not parser then
        return false
    end

    bottom_row = math.min(bottom_row, api.nvim_buf_line_count(buf) - 1)
    if bottom_row < top_row then
        return false
    end

    -- keep previous trees until an async parse finishes
    ensure_parsed(buf, parser, { top_row, bottom_row + 1 })

    local win_info = vim.fn.getwininfo(win)[1]
    if not win_info then
        return false
    end
    local leftcol = win_info.leftcol
    local tabstop = vim.bo[buf].tabstop
    local guides_by_row = collect_guides(buf, parser, tabstop, top_row, bottom_row)

    for row, columns in pairs(guides_by_row) do
        local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
        local indent, blank = leading_width(tabstop, line)
        for column in pairs(columns) do
            -- take care to never cover actual text
            if (blank or indent > column) and column >= leftcol then
                api.nvim_buf_set_extmark(buf, ns, row, 0, {
                    virt_text = { { GUIDE_CHAR, "IndentGuide" } },
                    virt_text_pos = "overlay",
                    virt_text_win_col = column - leftcol,
                    hl_mode = "combine",
                    ephemeral = true,
                })
            end
        end
    end

    return false
end

---@param buf? integer buffer handle, defaults to the current buffer
function M.enable(buf)
    buf = (buf == nil or buf == 0) and api.nvim_get_current_buf() or buf
    if enabled[buf] or not ts.get_parser(buf, nil, { error = false }) then
        return
    end
    if vim.bo[buf].vartabstop ~= "" then
        vim.notify_once("yi.indent_guides: 'vartabstop' is not supported", vim.log.levels.WARN)
    end
    enabled[buf] = "idle"
    api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
        buffer = buf,
        once = true,
        group = augroup,
        callback = function()
            enabled[buf] = nil
        end,
    })
    api.nvim__redraw { buf = buf, valid = false }
end

---@param buf? integer buffer handle, defaults to the current buffer
function M.disable(buf)
    buf = (buf == nil or buf == 0) and api.nvim_get_current_buf() or buf
    if not enabled[buf] then
        return
    end
    enabled[buf] = nil
    api.nvim_clear_autocmds { group = augroup, buffer = buf }
    api.nvim__redraw { buf = buf, valid = false }
end

local function setup_hls()
    local pal = require("yi.theme").palette()
    api.nvim_set_hl(0, "IndentGuide", { fg = pal.bg3 })
end

function M.setup()
    setup_hls()

    api.nvim_set_decoration_provider(ns, { on_win = on_win })

    api.nvim_create_autocmd("ColorScheme", {
        group = augroup,
        callback = setup_hls,
    })
    api.nvim_create_autocmd("FileType", {
        group = augroup,
        callback = function(args)
            M.enable(args.buf)
        end,
    })
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
            M.enable(buf)
        end
    end
end

return M
