local M = {}

function M.setup_rustaceanvim(capabilities)
    -- TODO this never worked on osx: spawned two rust-analyzers hogging the cpu (and draining battery)
    -- for now just switched to the buildin rust lsp
    local function on_attach(_, bufnr)
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
        --     default_settings = {
        --         ["rust-analyzer"] = {
        --             checkOnSave = false,
        --             procMacro = {
        --                 enable = false,
        --             },
        --             diagnostics = {
        --                 enable = true,
        --                 disabled = {},
        --                 enableExperimental = false,
        --             },
        --             hover = {
        --                 actions = {
        --                     enable = false,
        --                 },
        --             },
        --         },
        --     },
    }
end

function M.setup(capabilities)
    -- --- @type vim.lsp.ClientConfig
    vim.lsp.config("rust_analyzer", {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        capabilities = capabilities,
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
                        enable = true,
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
