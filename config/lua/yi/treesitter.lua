local mod = {}

function mod.setup()
    local query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { "BufWrite", "CursorHold" },
    }

    -- change some hl for visibility
    local palette = require("yi.theme").palette()
    vim.api.nvim_set_hl(0, "@comment.documentation", { fg = palette.cyan.dim })

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

return mod
