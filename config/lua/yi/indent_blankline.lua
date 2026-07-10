local M = {}

local function setup_hls()
    local pal = require("yi.theme").palette()
    vim.api.nvim_set_hl(0, "IblIndent", { fg = pal.bg2 })
    vim.api.nvim_set_hl(0, "IblScope", { fg = pal.bg3 })
end

function M.setup()
    setup_hls()

    require("ibl").setup {
        indent = { char = "│", highlight = "IblIndent" },
        scope = {
            char = "│",
            highlight = "IblScope",
            show_start = false,
            show_end = false,
            exclude = {
                node_type = {
                    rust = { "if_expression", "if_let_expression", "call_expression" },
                },
            },
        },
    }

    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = setup_hls,
    })
end

return M
