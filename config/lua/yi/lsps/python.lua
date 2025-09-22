local M = {}

function M.setup(capabilities)
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#basedpyright
    -- and https://github.com/detachhead/basedpyright or https://docs.basedpyright.com

    -- TODO this one seemed to work in single file mode?

    vim.lsp.config("basedpyright", {
        on_attach = function(client, bufnr)
            -- TODO could be cool, but no good highlight setup yet
            client.server_capabilities.semanticTokensProvider = true
            vim.lsp.inlay_hint.enable(false)
        end,
        capabilities = capabilities,
        settings = {
            -- see https://microsoft.github.io/pyright/#/settings
            -- (some are under pyright, some are under python)
            -- some settings are interesting, we can be more strict than the lint setting if we want
            basedpyright = {
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
    })

    vim.lsp.enable("basedpyright")
end

return M
