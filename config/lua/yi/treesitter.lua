local M = {}

function M.setup()
    -- change some hl for visibility
    local palette = require("yi.theme").palette()
    vim.api.nvim_set_hl(0, "@comment", { fg = palette.orange.dim })
    vim.api.nvim_set_hl(0, "@comment.documentation", { fg = palette.green.dim })
    vim.api.nvim_set_hl(0, "@comment.line", { fg = palette.orange.dim })

    -- handle TODO/NOTE highlighting with autocmd
    vim.api.nvim_set_hl(0, "@comment.todo", { fg = palette.green.bright, bold = true })
    vim.api.nvim_set_hl(0, "@comment.note", { fg = palette.blue.bright, bold = true })
    vim.api.nvim_set_hl(0, "@comment.safety", { fg = palette.red.bright, bold = true })
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
        callback = function()
            vim.fn.matchadd("@comment.todo", [[//.*\zs\<TODO\>]])
            vim.fn.matchadd("@comment.note", [[//.*\zs\<NOTE\>]])
            vim.fn.matchadd("@comment.safety", [[//.*\zs\<SAFETY\>]])
        end,
    })

    -- nvim-treesitter no longer manages modules
    -- use a FileType autocmd to start treesitter parsing per buffer
    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            pcall(vim.treesitter.start, args.buf)
        end,
    })
end

local context_patterns = {
    "class",
    "function",
    "method",
    "impl_item",
    "mod_item",
    "type_item",
    "struct_item",
    "function_item",
    "macro_invocation", -- TODO not working yet
}

function M.matching_ancestors(node, patterns)
    local at = node
    return function()
        while at do
            local current = at
            at = at:parent()
            for _, p in ipairs(patterns) do
                if current:type():find(p, 1, true) then
                    return current
                end
            end
        end
    end
end

---@return string[]
function M.get_context()
    local lines = {}

    local cursor = vim.api.nvim_win_get_cursor(0)
    table.insert(lines, vim.fn.expand("%") .. " @ " .. cursor[1] .. ":" .. (cursor[2] + 1))

    local trim = function(line)
        return line:gsub("%s*[%[%(%{]*%s*$", "")
    end

    local contexts = {}
    for node in M.matching_ancestors(vim.treesitter.get_node(), context_patterns) do
        local start_row = node:start()
        local line = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1] or ""
        line = trim(line)
        if line ~= "" then
            table.insert(contexts, line)
        end
    end

    local indent = "  "
    for i = #contexts, 1, -1 do
        table.insert(lines, indent .. contexts[i])
        indent = indent .. "  "
    end

    return lines
end

function M.jump_to_enclosing_fn()
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local node = M.matching_ancestors(vim.treesitter.get_node(), { "function", "method" })()
    if node then
        local fn_row = node:start() + 1
        if fn_row ~= cursor_row then
            vim.api.nvim_win_set_cursor(0, { fn_row, 0 })
        end
    end
end

return M
