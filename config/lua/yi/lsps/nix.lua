local M = {}

function M.setup(capabilities)
    vim.lsp.config("nil_ls", {
        cmd = { "nil" },
        capabilities = capabilities,
        root_markers = { "flake.nix", ".git" },
        filetypes = { "nix" },
    })

    vim.lsp.enable("nil_ls")
end

return M
