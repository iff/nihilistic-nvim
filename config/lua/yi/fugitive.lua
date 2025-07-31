local M = {}

function M.git()
    vim.cmd([[tab Git]])
end

function M.setup()
    -- see https://github.com/tpope/vim-fugitive
    vim.g["fugitive_no_maps"] = 1

    -- NOTE needs to happen after the theme is set
    -- because themes will overwrite it again otherwise (most of them anyway)
    vim.cmd([[
        highlight fugitiveUnstagedSection gui=bold
        highlight fugitiveStagedSection gui=bold
        highlight link diffLine GruvboxBlueSign
        highlight link diffSubname GruvboxBlueSign
        highlight link fugitiveHunk Comment
    ]])

    -- TODO generally fugitive has good mappings, read again and again before trying to fix things
    -- it also extends vims diffview a bit, same there before mapping stuff
    -- was thinking about < and > to put and get (dp and do)

    -- see https://github.com/tpope/vim-fugitive/issues/1425
    -- not sure which event now did it
    -- so I get the basic maps again from basics.lua and apply them this time with <buffer>?
    -- I already have them in topics, so should be easy enough to reuse
    -- TODO use filetype here too? ("fugitive")
    vim.api.nvim_create_autocmd("User", {
        pattern = { "FugitiveIndex", "FugitiveObject" },
        callback = M.status_config,
    })

    vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = { "gitcommit" },
        callback = M.gitcommit_config,
    })

    require('gitsigns').setup({
        on_attach = function(bufnr)
            local gitsigns = require('gitsigns')

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            map('n', 'ge', function()
                if vim.wo.diff then
                    vim.cmd.normal({ ']c', bang = true })
                else
                    gitsigns.nav_hunk('next')
                end
            end)

            map('n', 'gu', function()
                if vim.wo.diff then
                    vim.cmd.normal({ '[c', bang = true })
                else
                    gitsigns.nav_hunk('prev')
                end
            end)
        end,
    })
end

local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = true, nowait = true, desc = desc })
end

function M.status_config()
    local n, nv = "n", { "n", "v" }

    map(nv, "k", "k", "cursor up")
    map(nv, "h", "j", "cursor down")

    map(n, "u", "<Plug>fugitive:(", "previous file, hunk, or revision")
    map(n, "e", "<Plug>fugitive:)", "next file, hunk, or revision")

    map(n, "n", "<Plug>fugitive:<", "fold inline diff")
    map(n, "i", "<Plug>fugitive:>", "unfold inline diff")

    map(nv, "t", "<Plug>fugitive:-", "stage or unstage")
    map(n, "q", "<Plug>fugitive:U", "unstage everything")

    -- TODO on a big monitor, seeing the diff in a split instead of inline might be nicer
    map("n", "d", "<Plug>fugitive:O<cmd>Gvdiff<enter>", "diff in tab")
    map("n", "g", "<Plug>fugitive:O", "open file")

    map(n, "cc", "<cmd>Git commit --quiet<enter>")
    map(n, "cn", "<cmd>Git commit --no-verify --quiet<enter>")
    map(n, "ce", "<cmd>Git commit --amend --quiet<enter>")

    map(n, "ru", "<cmd>Git push<enter>")

    map(n, "rr", "<cmd>tab Git<enter>", "refresh status")
    map(n, "w,", "<cmd>tabclose<enter>", "close tab")
end

function M.gitcommit_config()
    vim.bo.textwidth = 0
    local n, i = "n", "i"
    map(n, "<esc>", "<cmd>x<enter>")
    map(n, "c", "<cmd>x<enter>")
    map(n, "q", "ggdG<cmd>:wq<enter>")
    map(i, "<c-o>", "<cmd>x<enter>")
    vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
        once = true,
        buffer = 0,
        callback = function()
            vim.cmd.startinsert()
        end,
    })
end

return M
