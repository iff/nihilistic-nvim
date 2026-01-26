local M = {}

function M.main()
    require("yi.options").setup()
    require("yi.theme").setup()
    require("yi.options").set()

    require("yi.neovide").setup()

    -- no config
    require("auspicious-autosave").setup()

    -- todo
    local layouts = require("lavish-layouts")
    layouts.setup()
    layouts.switch("dynamic")

    -- my config
    require("yi.oil").setup()
    require("yi.hop").setup()
    require("yi.telescope").setup()
    require("yi.completion").setup()
    require("yi.lsp").setup(require("yi.completion").get_capabilities())
    require("yi.fugitive").setup()
    require("yi.formatter").setup()
    require("yi.diagnostic").setup()
    require("yi.treesitter").setup()

    require("yi.mappings").apply()
end

return M
