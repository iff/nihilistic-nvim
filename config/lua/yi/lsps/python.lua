local M = {}

function M.setup()
    -- TODO only for ty?
    local capabilities = {
        workspace = {
            didChangeWatchedFiles = { dynamicRegistration = true },
            diagnostics = { refreshSupport = true },
        },
        textDocument = {
            diagnostic = { dynamicRegistration = true },
        },
    }

    vim.lsp.config("ty", {
        ---@param client vim.lsp.Client
        ---@param initialization_result lsp.InitializeResult
        on_init = function(client, _initialization_result)
            -- we cant do vim.lsp.buf.workspace_diagnostics before the capabilities are dynamically registered
            -- (and we want that, `diagnosticMode = "workspace"` doesnt seem to do anything)
            -- TODO I think eventually there must be a better way
            local handler = client.handlers["client/registerCapability"]
                or vim.lsp.handlers["client/registerCapability"]
            local tried = false
            client.handlers["client/registerCapability"] = function(...)
                local ret = handler(...)
                if not tried then
                    vim.lsp.buf.workspace_diagnostics { client_id = client.id }
                    -- NOTE we only do it once, maybe there is a way to check if the cap has been set
                    tried = true
                end
                return ret
            end
        end,
        capabilities = capabilities,
        init_options = {
            -- logLevel = "debug",
            -- logFile = "/tmp/lsp-ty",
            diagnosticMode = "workspace",
        },
        settings = {
            ty = {
                diagnosticMode = "workspace",
                inlayHints = {
                    variableTypes = false,
                },
            },
        },
    })
    vim.lsp.enable("ty")

    -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#basedpyright
    -- and https://github.com/detachhead/basedpyright or https://docs.basedpyright.com

    -- TODO this one seemed to work in single file mode?

    -- vim.lsp.config("basedpyright", {
    --     on_attach = function(client, bufnr)
    --         -- TODO could be cool, but no good highlight setup yet
    --         client.server_capabilities.semanticTokensProvider = nil
    --         vim.lsp.inlay_hint.enable(false)
    --     end,
    --     capabilities = capabilities,
    --     settings = {
    --         -- see https://microsoft.github.io/pyright/#/settings
    --         -- (some are under pyright, some are under python)
    --         -- some settings are interesting, we can be more strict than the lint setting if we want
    --         basedpyright = {
    --             -- pyright.disableLanguageServices if we want to use basedpyright?
    --             -- pyright.disableTaggedHints
    --             disableOrganizeImports = true,
    --             disableTaggedHints = false, -- graying out stuff or striking through
    --             analysis = {
    --                 autoImportCompletions = true,
    --                 -- TODO what marks a workspace?
    --                 diagnosticMode = "workspace",
    --                 useLibraryCodeForTypes = true,
    --                 -- only basedpyright
    --                 inlayHints = {
    --                     -- TODO setting to false doesnt seem to change anything. wrong setting path?
    --                     variableTypes = true,
    --                     callArgumentNames = true,
    --                     functionReturnTypes = true,
    --                     genericTypes = true,
    --                 },
    --             },
    --         },
    --     },
    -- })

    -- vim.lsp.enable("basedpyright")
end

return M
