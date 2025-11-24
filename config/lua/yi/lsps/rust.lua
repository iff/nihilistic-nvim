local M = {}

function M.setup_(capabilities)
    function on_attach(client, bufnr)
        local function nmap(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
        end

        nmap("ad", ":RustLsp openDocs<CR>", "go to docs")
    end

    vim.g.rustaceanvim = {
        server = {
            on_attach = on_attach,
            capabilities = capabilities,
        },
        default_settings = {
            ["rust-analyzer"] = {
                checkOnSave = false,
                procMacro = {
                    enable = false,
                },
                diagnostics = {
                    enable = true,
                    disabled = {},
                    enableExperimental = false,
                },
                hover = {
                    actions = {
                        enable = false,
                    },
                },
            },
        },
    }
end

function M.setup(capabilities)
    -- vim.lsp.config(
    --     "rust_analyzer",
    --     --- @type vim.lsp.ClientConfig
    --     {
    --         cmd = { "rust-analyzer" },
    --         filetypes = { "rust" },
    --         capabilities = vim.tbl_deep_extend("force", capabilities, {
    --             experimental = {
    --                 commands = {
    --                     commands = {
    --                         "rust-analyzer.showReferences",
    --                     },
    --                 },
    --             },
    --         }),
    --         settings = {
    --             ["rust-analyzer"] = {
    --                 checkOnSave = false,
    --                 -- procMacro = {
    --                 --     enable = false,
    --                 -- },
    --                 -- diagnostics = {
    --                 --     enable = true,
    --                 --     disabled = {},
    --                 --     enableExperimental = false,
    --                 -- },
    --                 -- hover = {
    --                 --     actions = {
    --                 --         enable = false,
    --                 --     },
    --                 -- },
    --                 lens = {
    --                     enable = true,
    --                     run = {
    --                         enable = true,
    --                     },
    --                     implementations = {
    --                         enable = true,
    --                     },
    --                     references = {
    --                         adt = {
    --                             enable = true,
    --                         },
    --                         method = {
    --                             enable = true,
    --                         },
    --                         trait = {
    --                             enable = true,
    --                         },
    --                         enumVariant = {
    --                             enable = true,
    --                         },
    --                     },
    --                 },
    --             },
    --         },
    --     }
    -- )

    vim.lsp.config("rust_analyzer", {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        capabilities = capabilities,
        settings = {
            ["rust-analyzer"] = {
                check = {
                    command = "clippy",
                },
                diagnostics = {
                    enable = true,
                    experimental = {
                        enable = true,
                    },
                },
            },
        },
    })

    vim.lsp.enable("rust_analyzer")
end

return M
