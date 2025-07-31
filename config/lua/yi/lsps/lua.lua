local M = {}

local function get_lua_settings_neodev()
    -- NOTE it will not complain for wrong keys or values, it just ignores them :/
    return {
        Lua = {
            runtime = {
                -- I dont know why "Lua 5.1" needs a number, but "LuaJIT" doesnt
                -- https://api7.ai/learning-center/openresty/luajit-vs-lua says LuaJIT is 5.1 syntax (?)
                version = "LuaJIT",
            },
            workspace = {
                ignoreDir = {}, -- uses gitignore grammar, files or dirs
                ignoreSubmodules = false,
                maxPreload = 10000, -- count
                preloadFileSize = 50000, -- kb
                useGitIgnore = true,
                userThirdParty = {}, -- what is the difference here? also it says absolute path
                checkThirdParty = false, -- TODO not sure, but it always pops up
                -- TODO not clear if this early at startup we do have the full list of runtimes
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
            -- see https://github.com/LuaLS/lua-language-server/wiki/Settings
            completion = {
                -- NOTE could be okay to enable
                showWord = "Disable",
                whorkspaceWord = false,
            },
            diagnostics = {
                -- globals = { "vim" },  -- TODO neodev does it?
                workspaceDelay = 1000,
                workspaceEvent = "OnChange",
            },
            format = {
                enable = false,
            },
            hint = {
                -- TODO doesnt work, nvim lsp problem instead? inline hints?
                -- or is it meant to be seen only in shift-k mode? hover?
                enable = true,
                arrayIndex = "Enable",
                setType = true,
            },
            -- TODO enabled by default, but does nvim do it?
            -- semantic coloring
            -- semantic = {
            --     enable=true,
            -- }
        },
    }
end

function M.setup(capabilities)
    -- using https://github.com/luals/lua-language-server
    -- alternative language server https://github.com/Alloyed/lua-lsp (looks unfinished and inactive)

    -- see https://github.com/folke/neodev.nvim
    -- sets up things for neovim lua development
    -- require("neodev").setup({})

    -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#lua_ls
    require("lspconfig").lua_ls.setup {
        cmd = { "lua-language-server" },
        -- see https://github.com/LuaLS/lua-language-server/wiki/Configuration-File
        settings = get_lua_settings_neodev(),
        -- on_attach = M.mappings,
        capabilities = capabilities,
    }
end

return M
