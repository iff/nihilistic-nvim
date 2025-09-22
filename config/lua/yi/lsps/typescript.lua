local M = {}

function M.setup(capabilities)
    vim.lsp.config("ts_ls", {
        capabilities = capabilities,
    })

    vim.lsp.enable("ts_ls")
end

return M
