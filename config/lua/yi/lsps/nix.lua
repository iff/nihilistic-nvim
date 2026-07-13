local M = {}

function M.setup()
    vim.lsp.config("nil_ls", {
        settings = { -- https://github.com/oxalica/nil/blob/main/docs/configuration.md
            ["nil"] = {
                nix = {
                    maxMemoryMB = 10000,
                    flake = {
                        autoArchive = true,
                        -- TODO this could be dangerous?
                        autoEvalInputs = true,
                        nixpkgsInputName = "nixpkgs",
                    },
                },
            },
        },
    })

    vim.lsp.enable("nil_ls")
end

return M
