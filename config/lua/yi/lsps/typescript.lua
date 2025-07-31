local M = {}

function M.setup(capabilities)
    require("lspconfig").ts_ls.setup {
        capabilities = capabilities,
    }
end

return M
