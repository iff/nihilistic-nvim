local M = {}

function M.setup()
    -- works quite well by now
    --   nvim --listen ./socket --headless
    --   nvim --server ./socket --remote-ui
    --   neovide --server ./socket
    --   :detach, and doesnt kill the server even if last, even if it was its own ui (no --headless)
    -- but still difficult to switch from inside, unless we get a per-project nvim server or something
    -- so for now using sessions and ep and things like that, and some that start neovide instead

    if not vim.g.neovide then
        return
    end

    -- see https://neovide.dev/configuration.html
    -- see also ./config.toml

    vim.go.guifont = "ZedMono Nerd Font Mono:h13"
    vim.g.neovide_hide_mouse_when_typing = true
    vim.o.winblend = 0
    vim.go.pumblend = 0
    vim.g.mouse = "a"
    vim.g.neovide_refresh_rate = 160
end

return M
