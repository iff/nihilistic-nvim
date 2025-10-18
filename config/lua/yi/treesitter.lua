local M = {}

function M.setup()
    local query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { "BufWrite", "CursorHold" },
    }

    -- change some hl for visibility
    local palette = require("yi.theme").palette()
    vim.api.nvim_set_hl(0, "@comment.documentation", { fg = palette.blue.dim })

    require("nvim-treesitter.configs").setup {
        highlight = {
            enable = true,
        },
        incremental_selection = {
            enable = false,
            -- TODO try
            -- keymaps = {
            --     init_selection = "gnn",
            --     node_incremental = "grn",
            --     scope_incremental = "grc",
            --     node_decremental = "grm",
            -- },
        },
        indent = { enable = false },
        query_linter = query_linter,
    }
end

---@return string[]
function M.get_context()
    local lines = {}

    local cursor = vim.api.nvim_win_get_cursor(0)
    table.insert(lines, vim.fn.expand("%") .. " @ " .. cursor[1] .. ":" .. (cursor[2] + 1))

    local ts_utils = require("nvim-treesitter.ts_utils")

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

    local contexts = {}
    local at = ts_utils.get_node_at_cursor()
    while at do
        local line = ts_utils._get_line_for_node(at, type_patterns, transform_fn, 0)
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
