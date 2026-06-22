local M = {}

function M.setup(capabilities)
    local default_root_dir = vim.lsp.config["rust_analyzer"].root_dir
    local default_before_init = vim.lsp.config["rust_analyzer"].before_init

    -- --- @type vim.lsp.ClientConfig
    vim.lsp.config("rust_analyzer", {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        capabilities = capabilities,
        root_dir = function(bufnr, on_dir)
            local git_root = vim.fs.root(bufnr, { ".git" })
            if git_root and vim.uv.fs_stat(vim.fs.joinpath(git_root, "src/etc/rust_analyzer_zed.json")) then
                on_dir(git_root)
                return
            end
            default_root_dir(bufnr, on_dir)
        end,
        before_init = function(init_params, config)
            local settings_path = vim.fs.joinpath(config.root_dir, "src/etc/rust_analyzer_zed.json")
            if vim.uv.fs_stat(settings_path) then
                local file = io.open(settings_path)
                local json = vim.json.decode(file:read("*a"), { skip_comments = true })
                file:close()
                config.settings["rust-analyzer"] = vim.tbl_deep_extend(
                    "force",
                    config.settings["rust-analyzer"] or {},
                    json.lsp["rust-analyzer"].initialization_options
                )
            end
            if default_before_init then
                default_before_init(init_params, config)
            end
        end,
        -- capabilities = vim.tbl_deep_extend("force", capabilities, {
        --     experimental = {
        --         commands = {
        --             commands = {
        --                 "rust-analyzer.showReferences",
        --             },
        --         },
        --     },
        -- }),
        settings = {
            ["rust-analyzer"] = {
                -- checkOnSave = false,
                cargo = {
                    allFeatures = true,
                },
                check = {
                    command = "clippy",
                },
                diagnostics = {
                    enable = true,
                    experimental = {
                        enable = false,
                    },
                },
                -- procMacro = {
                --     enable = false,
                -- },
                -- lens = {
                --     enable = true,
                --     run = {
                --         enable = true,
                --     },
                --     implementations = {
                --         enable = true,
                --     },
                --     references = {
                --         adt = {
                --             enable = true,
                --         },
                --         method = {
                --             enable = true,
                --         },
                --         trait = {
                --             enable = true,
                --         },
                --         enumVariant = {
                --             enable = true,
                --         },
                --     },
                -- },
            },
        },
    })

    vim.lsp.enable("rust_analyzer")
end

return M
