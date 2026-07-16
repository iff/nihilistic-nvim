local M = {}

function M.setup()
    vim.lsp.config("leanls", {
        cmd = { "lake", "serve", "--" },
        filetypes = { "lean" },
        root_markers = { "lakefile.toml", "lakefile.lean", "lean-toolchain", ".git" },
    })

    vim.lsp.enable("leanls")
end

return M
