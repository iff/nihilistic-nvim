local M = {}

-- TODO builtin.resume could be interesting when jumping around with diagnostics!

local builtin = require("telescope.builtin")

local function laforge()
    require("telescope.pickers.layout_strategies").laforge = function(self, max_columns, max_lines, layout_config)
        -- local resolve = require("telescope.config.resolve")
        -- local p_window = require("telescope.pickers.window")
        -- local initial_options = p_window.get_initial_window_options(self)
        -- local results = initial_options.results
        -- local prompt = initial_options.prompt
        -- local preview = initial_options.preview
        local half = vim.fn.round(max_lines / 2)
        local pad = 3
        return {
            preview = {
                border = true,
                borderchars = { "─", "│", "═", "│", "┌", "┐", "╛", "╘" },
                col = 2,
                enter = false,
                height = half - pad - 3,
                line = 2,
                width = max_columns - 2,
            },
            prompt = {
                border = true,
                borderchars = { "═", "│", "─", "│", "╒", "╕", "│", "│" },
                col = 2,
                enter = true,
                height = 1,
                line = half + pad + 2,
                title = self.prompt_title,
                width = max_columns - 2,
            },
            results = {
                border = { 0, 1, 1, 1 },
                borderchars = { "═", "│", "─", "│", "╒", "╕", "┘", "└" },
                col = 2,
                enter = false,
                height = max_lines - half - pad - 4,
                line = half + pad + 4,
                width = max_columns - 2,
            },
        }
    end

    local defaults = {
        -- TODO how to make the layout strat and the rest go together? many things are not independent, like sorting_strategy
        layout_strategy = "laforge",
        sorting_strategy = "ascending",
        prompt_prefix = "󰄾 ",
        entry_prefix = "   ",
        selection_caret = " 󰧚 ",
    }
    defaults.scroll_strategy = "limit"
    defaults.path_display = { "truncate" }
    return defaults
end

local function flex()
    return {
        layout_strategy = "flex",
        layout_config = {},
    }
end

function M.setup()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    -- defaults = flex()
    defaults = laforge()

    defaults["mappings"] = {
        i = {
            ["<c-e>"] = actions.move_selection_next,
            ["<c-u>"] = actions.move_selection_previous,
            ["<enter>"] = actions.select_default,
        },
        n = {
            ["e"] = "move_selection_next",
            ["u"] = "move_selection_previous",
            ["<enter>"] = actions.select_default,
        },
    }

    -- see https://github.com/nvim-telescope/telescope.nvim
    -- TODO see again dependencies, fd and stuff, bundle it?
    ---@diagnostic disable-next-line:redundant-parameter
    telescope.setup {
        defaults = defaults,
        -- {
        --     layout_strategy = "flex",
        --     layout_config = {},
        --     mappings = mappings,
        -- },
        extensions = {
            -- see https://github.com/nvim-telescope/telescope-fzf-native.nvim
            fzf = {},
            -- see https://github.com/nvim-telescope/telescope-ui-select.nvim
            ["ui-select"] = {},
        },
    }
    telescope.load_extension("fzf")
    telescope.load_extension("ui-select")
end

local function at_top()
    vim.cmd([[normal! zt]])
end

---@diagnostic disable-next-line: unused-local, unused-function
local function jump_find_files(entry)
    -- { "config/lua/dk/mappings.lua",
    --   index = 4,
    --   <metatable> = {
    --     __index = <function 1>,
    --     cwd = "/home/dkuettel/config/i/nvim",
    --     display = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry[1]))
end

---@diagnostic disable-next-line: unused-local, unused-function
local function jump_help_tags(entry)
    -- {
    --   cmd = "/*:map-nowait*",
    --   display = ":map-nowait",
    --   filename = "/nix/store/g6k5yzipk2ianqxj1d3xj1ab19kc31lf-neovim-unwrapped-0.10.3/share/nvim/runtime/doc/map.txt",
    --   index = 2300,
    --   ordinal = ":map-nowait",
    --   <metatable> = {
    --     __index = <function 1>
    --   }
    -- }
    -- NOTE vim's help handling is a bit bumpy
    -- the trick is to make a new buffer of type "help" so that :help decides to use it
    -- this way we can control where it ends up predictably
    vim.cmd.enew() -- NOTE doesnt seem to leave unused unnamed buffers around, even thou I expected it to
    vim.bo.buftype = "help" -- NOTE documentation says dont do this, but no problem so far
    vim.cmd.help(entry.display) -- TODO might have to escape here?
end

local function jump_lsp_symbol(entry)
    -- lsp symbol
    -- {
    --   col = 12,
    --   display = <function 1>,
    --   filename = "/home/dkuettel/config/i/nvim/config/lua/dk/mappings.lua",
    --   index = 583,
    --   lnum = 286,
    --   ordinal = "M.for_visual Function",
    --   symbol_name = "M.for_visual",
    --   symbol_type = "Function",
    --   <metatable> = {
    --     __index = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
    vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
    at_top()
end

---@diagnostic disable-next-line: unused-local, unused-function
local function jump_live_grep(entry)
    -- { "dev/run-tmux-bound-gg:5:12:# tmux new-window iloop run --until -- nix run '.?submodules=1#default' -- config/lua/dk/nvim.lua",
    --   col = 12,
    --   filename = "dev/run-tmux-bound-gg",
    --   index = 1,
    --   lnum = 5,
    --   text = "# tmux new-window iloop run --until -- nix run '.?submodules=1#default' -- config/lua/dk/nvim.lua",
    --   <metatable> = {
    --     __index = <function 1>,
    --     cwd = "/home/dkuettel/config/i/nvim",
    --     display = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
    vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
    at_top()
end

---@diagnostic disable-next-line: unused-local, unused-function
local function jump_buffers(entry)
    -- {
    --   bufnr = 1,
    --   display = <function 1>,
    --   filename = "config/lua/dk/nvim.lua",
    --   index = 1,
    --   indicator = "%a  ",
    --   lnum = 1,
    --   ordinal = "1 : config/lua/dk/nvim.lua",
    --   path = "/home/dkuettel/config/i/nvim/config/lua/dk/nvim.lua",
    --   <metatable> = {
    --     __index = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
end

---@diagnostic disable-next-line: unused-local, unused-function
local function jump_diagnostics(entry)
    -- {
    --   col = 1,
    --   display = <function 1>,
    --   filename = "/home/dkuettel/config/i/nvim/config/lua/dk/nvim.lua",
    --   index = 1,
    --   lnum = 3,
    --   ordinal = " Unexpected <exp> .",
    --   text = "Unexpected <exp> .",
    --   type = "ERROR",
    --   <metatable> = {
    --     __index = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
    vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
    at_top()
end

---@diagnostic disable-next-line: unused-local, unused-function
local function jump_man(entry)
    -- {
    --   description = "search for files in a directory hierarchy",
    --   display = <function 1>,
    --   index = 867,
    --   keyword = "find (1)",
    --   ordinal = "find",
    --   section = "1",
    --   value = "find",
    --   <metatable> = {
    --     __index = <function 2>
    --   }
    -- }
    -- TODO probably needs escaping?
    vim.cmd.edit("man://" .. entry.value .. "(" .. entry.section .. ")")
end

---@diagnostic disable-next-line: unused-local, unused-function
local function jump_marks(entry)
    -- {
    --   col = 39,
    --   display = 'a      9   38     -- vim.cmd.colorscheme("retrobox")',
    --   filename = "/home/dkuettel/config/i/nvim/config/lua/dk/nvim.lua",
    --   index = 1,
    --   lnum = 9,
    --   ordinal = 'a      9   38     -- vim.cmd.colorscheme("retrobox")',
    --   <metatable> = {
    --     __index = <function 1>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
    vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
    at_top()
end

---@param picker
---@param jump?
---@param opts?
---@return fun(make: fun()) op
local function as_op(picker, jump, opts)
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    ---@param make fun()
    return function(make)
        local callback = {
            -- prompt_title = "buffer symbol", -- TODO should it come from outside? that its in-place, or a split?
            attach_mappings = function(prompt_bufnr, map)
                local function enter(prompt_bufnr)
                    local entry = state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if not entry then
                        return
                    end
                    make()
                    if jump then
                        jump(entry)
                    else
                        vim.print(entry)
                    end
                end
                map("i", "<enter>", enter)
                map("n", "<enter>", enter)
                return true
            end,
        }
        local merged = vim.tbl_deep_extend("force", opts or {}, callback)
        picker(merged)
    end
end

function M.pick_resume()
    builtin.resume()
end

function M.pick_file()
    builtin.find_files()
end

function M.pick_jumplist()
    builtin.jumplist { initial_mode = "normal" }
end

function M.pick_file_config()
    builtin.find_files { prompt_title = "config files", search_dirs = { "~/src/dotfiles" } }
end

function M.pick_grep()
    builtin.live_grep()
end

function M.pick_buffer()
    builtin.buffers()
end

function M.pick_references()
    builtin.lsp_references()
end

function M.pick_help()
    -- TODO not sure how to handle things when we cancel things
    vim.cmd.enew() -- NOTE doesnt seem to leave unused unnamed buffers around, even thou I expected it to
    vim.bo.buftype = "help" -- NOTE documentation says dont do this, but no problem so far
    vim.bo.filetype = "help" -- not sure this is needed, or good?
    builtin.help_tags()
end

function M.pick_man()
    builtin.man_pages()
end
function M.pick_man_all()
    builtin.man_pages { sections = { "ALL" } }
end

function M.pick_mark()
    builtin.marks { initial_mode = "normal" }
end

function M.pick_project_symbol()
    if vim.bo.filetype == "python" then
        local ptags = require("ptags")
        local function ptags_workspace()
            -- TODO could we use a defined venv?
            -- should ptags itself be able to do that?
            local sources = {
                vim.fn.glob("python", false, true),
                vim.fn.glob("src", false, true),
                vim.fn.glob("libs/*/python", false, true),
            }
            sources = vim.iter(sources):flatten(math.huge):totable()
            if #sources == 0 then
                sources = { "." }
            end
            ptags.telescope(sources)
        end
        ptags_workspace()
    else
        local make = function() end
        as_op(builtin.lsp_dynamic_workspace_symbols(), jump_lsp_symbol)(make)
    end
end

function M.pick_buffer_symbol()
    if vim.bo.filetype == "python" then
        local ptags = require("ptags")
        local function ptags_local()
            ptags.telescope { vim.fn.expand("%") }
        end
        ptags_local()
    else
        local make = function() end
        as_op(builtin.lsp_document_symbols, jump_lsp_symbol)(make)
    end
end

function M.pick_buffer_diagnostic()
    -- TODO needed to set severity because of a bug, otherwise shows nothing, still true?
    -- see https://github.com/nvim-telescope/telescope.nvim/issues/2661
    builtin.diagnostics { initial_mode = "normal", bufnr = 0, severity_limit = vim.diagnostic.severity.ERROR }
end

function M.pick_buffer_diagnostic_all()
    builtin.diagnostics { initial_mode = "normal", bufnr = 0, severity_limit = vim.diagnostic.severity.HINT }
end

function M.pick_project_diagnostics()
    builtin.diagnostics {
        initial_mode = "normal",
        bufnr = nil,
        no_unlisted = false,
        severity_limit = vim.diagnostic.severity.ERROR,
    }
end

function M.pick_project_diagnostics_all()
    builtin.diagnostics {
        initial_mode = "normal",
        bufnr = nil,
        no_unlisted = false,
        severity_limit = vim.diagnostic.severity.HINT,
    }
end

function M.pick_diff_files()
    builtin.find_files {
        prompt_title = "files with diff",
        find_command = { "zsh", "-c", "git diff --name-only master 2>/dev/null || git diff --name-only main" },
        initial_mode = "normal",
    }
end

return M
