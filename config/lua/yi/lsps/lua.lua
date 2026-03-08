local M = {}

function M.setup(capabilities)
    vim.lsp.config("lua_ls", {
        -- --loglevel: error warn info debug trace
        -- cmd = { "lua-language-server", "--logpath", "lua-ls.log", "--loglevel", "info" },
        capabilities = capabilities,
        workspace_required = true,
        settings = {
            -- NOTE it will not complain for wrong keys or values, it just ignores them :/
            -- see https://luals.github.io/wiki/configuration/
            Lua = {
                workspace = {
                    maxPreload = 100000, -- count
                    preloadFileSize = 500000, -- kb
                    checkThirdParty = false, -- TODO not sure, but it always pops up
                },
                telemetry = {
                    enable = false,
                },
                type = {
                    checkTableShape = true, -- TODO unofficial, and not sure it actually has an effect anymore
                    castNumberToInteger = false,
                    inferTableSize = 1000,
                },
                completion = {
                    -- NOTE could be okay to enable
                    showWord = "Disable",
                    whorkspaceWord = false,
                    -- TODO below trying out newly
                    callSnippet = "Both",
                    keywordSnippet = "Both",
                    displayContext = 10,
                },
                diagnostics = {
                    workspaceDelay = 1000,
                    workspaceEvent = "OnChange",
                },
                format = {
                    enable = false,
                },
                hint = {
                    enable = true,
                    arrayIndex = "Enable",
                    setType = true,
                },
                semantic = {
                    -- TODO mixed bag ... my hl groups are not setup well
                    enable = true,
                },
            },
        },
    })
    vim.lsp.enable("lua_ls")
    -- TODO try emmylua_ls
    -- vim.lsp.enable("emmylua_ls")
end

return M
