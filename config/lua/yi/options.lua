local mod = {}

local leader_map = function()
    vim.g.mapleader = ","
    vim.g.maplocalleader = ","
end

local disable_distribution_plugins = function()
    vim.g.loaded_gzip = 1
    vim.g.loaded_tar = 1
    vim.g.loaded_tarPlugin = 1
    vim.g.loaded_zip = 1
    vim.g.loaded_zipPlugin = 1
    vim.g.loaded_getscript = 1
    vim.g.loaded_getscriptPlugin = 1
    vim.g.loaded_vimball = 1
    vim.g.loaded_vimballPlugin = 1
    vim.g.loaded_matchit = 1
    vim.g.loaded_matchparen = 1
    vim.g.loaded_2html_plugin = 1
    vim.g.loaded_logiPat = 1
    vim.g.loaded_rrhelper = 1
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    vim.g.loaded_netrwSettings = 1
    vim.g.loaded_netrwFileHandlers = 1
end

function mod.setup()
    disable_distribution_plugins()
    leader_map()
end

function mod.set()
    local set = vim.opt

    set.writebackup = false
    set.swapfile = false

    set.backspace = { "indent", "eol", "start", "nostop" }
    set.scrolloff = 8 -- 9999
    set.jumpoptions = { "view" }
    set.wildmode = "longest:full"

    set.tabstop = 4
    set.softtabstop = 4
    set.shiftwidth = 4
    set.expandtab = true
    set.smarttab = true
    set.autoindent = true
    set.copyindent = true
    set.textwidth = 0
    set.indentexpr = ""
    set.indentkeys = ""
    set.cinkeys = ""
    set.formatoptions = ""

    set.modeline = false
    set.modelines = 0

    set.smoothscroll = true
    set.mouse = ""

    set.timeout = false
    set.ttimeout = true

    set.cmdwinheight = 10

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        desc = "relayout on resize",
        callback = function()
            local t = vim.api.nvim_get_current_tabpage()
            vim.cmd("tabdo wincmd =")
            vim.api.nvim_set_current_tabpage(t)
        end,
    })

    -- flash yanking
    vim.api.nvim_create_autocmd("TextYankPost", {
        pattern = "*",
        callback = function()
            vim.highlight.on_yank {
                higroup = "@comment.Note",
                timeout = 100,
            }
        end,
    })

    -- TODO find a better place for ft
    vim.cmd([[
      autocmd FileType python imap <buffer> <F11>b breakpoint()
      autocmd FileType python imap <buffer> <F11>a # TODO
      autocmd FileType rust imap <buffer> <F11>a todo!()
    ]])

    -- TODO find a better place
    -- make sure we always scroll to the last line in term buffers
    vim.cmd([[
      augroup TermScroll
        autocmd!
        autocmd BufWinEnter,WinEnter term://* startinsert | autocmd BufWritePost <buffer> normal! G
        autocmd TermOpen * startinsert
      augroup END
    ]])
end

return mod
