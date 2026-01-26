local M = {}

function M.setup(capabilities)
    vim.lsp.config("cuda", {
        capabilities = capabilities,
    })

    vim.lsp.enable("cuda")
end

return M
