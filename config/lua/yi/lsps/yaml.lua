local M = {}

function M.setup(capabilities)
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#yamlls
    -- https://github.com/redhat-developer/yaml-language-server

    require("lspconfig").yamlls.setup {
        on_attach = M.mappings,
        capabilities = capabilities,
        settings = {
            redhat = {
                telemetry = {
                    enabled = false,
                },
            },
        },
    }
end

return M
