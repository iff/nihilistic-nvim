local M = {}

function M.setup(capabilities)
    vim.lsp.config("nil", {
        capabilities = capabilities,
    })

    vim.lsp.enable("nil")
end

return M
