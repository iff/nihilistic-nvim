local M = {}

function M.main()
    require("yi.options").setup()
    require("yi.theme").setup()
    require("yi.options").set()

    -- no config
    require("Comment").setup()
    require("auspicious-autosave").setup()

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
