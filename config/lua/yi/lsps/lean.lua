local M = {}

function M.setup(capabilities)
    vim.lsp.config("leanls", {
        capabilities = capabilities,
    })
    vim.lsp.enable("leanls")
end

return M
