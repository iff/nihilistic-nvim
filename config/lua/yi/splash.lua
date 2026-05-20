local M = {}

local function maybe_show(event)
    -- TODO my nvim wrapper defaults to '.' as arg
    if vim.fn.argc() == 1 and vim.fn.argv(0) == "." then
        require("snacks.picker").files()
    end
end

function M.setup()
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = maybe_show,
        once = true,
    })
end

return M
