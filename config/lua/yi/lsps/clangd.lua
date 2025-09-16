local M = {}

function M.setup(capabilities)
    require("lspconfig").clangd.setup {}
end

return M
