local M = {}

function M.setup(capabilities)
    vim.lsp.config("clangd", {
        capabilities = capabilities,
    })

    vim.lsp.enable("clangd")
end

return M
