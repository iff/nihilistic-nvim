local M = {}

function M.setup(capabilities)
    vim.lsp.config("ts_ls", {
        capabilities = capabilities,
    --     cmd = { "typescript-language-server", "--stdio" },
    --     filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    --     root_dir = vim.fs.root(0, { "package.json", "tsconfig.json", "jsconfig.json", ".git" }),
    --     settings = {
    --         typescript = {
    --             inlayHints = {
    --                 includeInlayParameterNameHints = "all",
    --                 includeInlayParameterNameHintsWhenArgumentMatchesName = false,
    --                 includeInlayFunctionParameterTypeHints = true,
    --                 includeInlayVariableTypeHints = true,
    --                 includeInlayPropertyDeclarationTypeHints = true,
    --                 includeInlayFunctionLikeReturnTypeHints = true,
    --                 includeInlayEnumMemberValueHints = true,
    --             },
    --         },
    --         javascript = {
    --             inlayHints = {
    --                 includeInlayParameterNameHints = "all",
    --                 includeInlayParameterNameHintsWhenArgumentMatchesName = false,
    --                 includeInlayFunctionParameterTypeHints = true,
    --                 includeInlayVariableTypeHints = true,
    --                 includeInlayPropertyDeclarationTypeHints = true,
    --                 includeInlayFunctionLikeReturnTypeHints = true,
    --                 includeInlayEnumMemberValueHints = true,
    --             },
    --         },
    --     },
    })

    vim.lsp.enable("biome")
    vim.lsp.enable("ts_ls")
end

return M
