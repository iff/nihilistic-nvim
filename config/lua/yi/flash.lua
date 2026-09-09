local mod = {}

function mod.setup()
    require("flash").setup {
        -- based on https://colemakmods.github.io/mod-dh/model.html
        labels = "ntseriufhdywoa",
        modes = {
            char = {
                -- NOTE this maps any of FfTt, and mappings.lua has a problem with that when deleting all default mappings
                -- it will break our submodes
                enabled = false,
            },
        },
    }
    vim.api.nvim_set_hl(0, "FlashCurrent", { underline = true })
    vim.api.nvim_set_hl(0, "FlashMatch", { underline = true })
    vim.api.nvim_set_hl(0, "FlashLabel", { link = "Search" })
end

return mod
