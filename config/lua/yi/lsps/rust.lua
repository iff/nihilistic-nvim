local M = {}

function M.setup(capabilities)
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
    }
end

return M
