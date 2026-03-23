local M = {}

function M.setup()
    -- change some hl for visibility
    local palette = require("yi.theme").palette()
    vim.api.nvim_set_hl(0, "@comment.documentation", { fg = palette.blue.dim })

    -- nvim-treesitter no longer manages modules
    -- use a FileType autocmd to start treesitter parsing per buffer
    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            pcall(vim.treesitter.start, args.buf)
        end,
    })
end

---@return string[]
function M.get_context()
    local lines = {}

    local cursor = vim.api.nvim_win_get_cursor(0)
    table.insert(lines, vim.fn.expand("%") .. " @ " .. cursor[1] .. ":" .. (cursor[2] + 1))

    local type_patterns = {
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
    local transform_fn = function(line, _node)
        return line:gsub("%s*[%[%(%{]*%s*$", "")
    end

    local function get_line_for_node(node)
        local node_type = node:type()
        for _, pattern in ipairs(type_patterns) do
            if node_type:find(pattern) then
                local start_row = node:range()
                local line = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1] or ""
                return transform_fn(line, node)
            end
        end
        return ""
    end

    local contexts = {}
    local at = vim.treesitter.get_node()
    while at do
        local line = get_line_for_node(at)
        if line ~= "" then
            table.insert(contexts, line)
        end
        at = at:parent()
    end

    local indent = "  "
    for i = #contexts, 1, -1 do
        table.insert(lines, indent .. contexts[i])
        indent = indent .. "  "
    end

    return lines
end

return M
