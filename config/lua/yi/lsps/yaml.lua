local M = {}

function M.setup(capabilities)
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#yamlls
    -- https://github.com/redhat-developer/yaml-language-server

    vim.lsp.config("yamlls", {
        capabilities = capabilities,
        cmd = { "yaml-language-server", "--stdio" },
        filetypes = { "yaml" },
        root_markers = { ".git" },
        settings = {
            redhat = {
                telemetry = {
                    enabled = false,
                },
            },
        },
    })

    vim.lsp.enable("yamlls")
end

return M
