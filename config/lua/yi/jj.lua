local M = {}

vim.api.nvim_create_autocmd("FileType", {
    pattern = "jjdescription",
    callback = function(args)
        vim.keymap.set("n", "<esc>", "<cmd>x<enter>", { buffer = args.buf, nowait = true })
    end,
})

function M.status()
    vim.cmd([[J log]])
end

function M.diff_main()
    vim.cmd([[J diff @..main]])
end

function M.setup()
    require("jj").setup {
        diff = {
            backend = "diffview",
        },
        terminal = {
            window = {
                type = "tab", -- TODO or floating?
            },
        },
    }
    require("hunk").setup {
        keys = {
            global = {
                quit = { "<esc>" },
                accept = { "cc" },
                focus_tree = { "<leader>t" },
            },
            tree = {
                collapse_node = { "n" },
                expand_node = { "i" },
                toggle_file = { "t" },
                open_file = { "<enter>" },
            },

            diff = {
                toggle_hunk = { "t" },
                toggle_line = { "a" },
                -- This is like toggle_line but it will also toggle the line on the other
                -- 'side' of the diff.
                -- toggle_line_pair = { "s" },

                prev_hunk = { "u" },
                next_hunk = { "e" },

                -- Jump between the left and right diff view
                toggle_focus = { "<tab>" },
            },
        },
        icons = {
            enable_file_icons = true,
        },
    }
end

return M
