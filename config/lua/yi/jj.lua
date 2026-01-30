local M = {}

function M.status()
    vim.cmd([[J log]])
end

function M.setup()
    require("jj").setup {}
end

return M
