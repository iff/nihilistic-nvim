local M = {}

function M.setup(capabilities)
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#basedpyright
    -- and https://github.com/detachhead/basedpyright or https://docs.basedpyright.com

    -- TODO this one seemed to work in single file mode?

    require("lspconfig").basedpyright.setup {
        on_attach = function(client, bufnr)
            -- TODO could be cool, but no good highlight setup yet
            client.server_capabilities.semanticTokensProvider = false
            vim.lsp.inlay_hint.enable(false)
        end,
        capabilities = capabilities,
        root_dir = function(filename, buffernr)
            return vim.fn.getcwd()
        end,
        -- single_file_support=false, -- TODO default is true, but not sure really what it does then
        settings = {
            -- see https://microsoft.github.io/pyright/#/settings
            -- (some are under pyright, some are under python)
            -- some settings are interesting, we can be more strict than the lint setting if we want
            basedpyright = {
                -- NOTE consider
                -- pyright.disableLanguageServices if we want to use basedpyright?
                -- pyright.disableTaggedHints
                disableOrganizeImports = true,
                disableTaggedHints = false, -- graying out stuff or striking through
                analysis = {
                    autoImportCompletions = true,
                    -- TODO what marks a workspace?
                    diagnosticMode = "workspace",
                    useLibraryCodeForTypes = true,
                    -- only basedpyright
                    inlayHints = {
                        -- TODO setting to false doesnt seem to change anything. wrong setting path?
                        variableTypes = true,
                        callArgumentNames = true,
                        functionReturnTypes = true,
                        genericTypes = true,
                    },
                },
            },
        },
    }
end

return M
