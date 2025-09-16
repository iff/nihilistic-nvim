local M = {}

function M.setup(capabilities)
    vim.lsp.enable("lua_ls")
end

return M
