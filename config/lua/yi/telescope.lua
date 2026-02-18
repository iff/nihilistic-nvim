local M = {}

local builtin = require("telescope.builtin")

local runtime_folders = nil

local at = require("telescope.actions.mt").transform_mod {
    center = function(_)
        vim.cmd([[normal! zz]])
    end,
    top = function(_)
        vim.cmd([[normal! zt]])
    end,
}

local function fn_mappings(post)
    -- TODO because setup can use .mappings, but a direct picker call can only do .attach_mappings
    -- which is ... arr why? currently the only thing we change is the post step
    -- so we assume the other settings come from above and are fine
    local actions = require("telescope.actions")
    local select = actions.select_default
    if post then
        select = select + post
    end
    return function(_, map)
        map({ "i", "n" }, "<enter>", select)
        return true -- means we also want the default mappings (not clear in what order)
    end
end

---@param default? string
---@return string
local function maybe_default_text(default)
    if vim.api.nvim_get_mode().mode ~= "v" then
        return default or ""
    end
    vim.cmd([[normal! "ay]])
    return vim.fn.getreg("a")
end

local function laforge()
    require("telescope.pickers.layout_strategies").laforge = function(self, max_columns, max_lines, _)
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

local function flex() ---@diagnostic disable-line: unused-function,unused-local
    return {
        layout_strategy = "flex",
        layout_config = {},
    }
end

local function flex_aspect_layout(self, max_columns, max_lines)
    local borderchars = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" }
    -- NOTE this is aligned with when lavish-layout switches in dynamic mode
    local narrow = max_columns <= 190
    if narrow then
        local border = 2
        local prompt = 1
        local results = 7
        return {
            prompt = {
                col = 2,
                line = max_lines - prompt,
                width = max_columns - border,
                height = prompt,
                enter = true,
                border = true,
                borderchars = borderchars,
                title = self.prompt_title,
            },
            results = {
                col = 2,
                line = max_lines - prompt - border - results,
                width = max_columns - border,
                height = results,
                enter = false,
                border = true,
                borderchars = borderchars,
                title = "results",
            },
            preview = {
                col = 2,
                line = 3,
                width = max_columns - border,
                height = max_lines - prompt - border - results - border - 3,
                enter = false,
                border = true,
                borderchars = borderchars,
                title = "preview",
            },
        }
    else -- not narrow
        local width = vim.fn.round(max_columns / 2)
        local border = 2
        local prompt = 1
        return {
            prompt = {
                col = 2,
                line = max_lines - prompt,
                width = width - border,
                height = prompt,
                enter = true,
                border = true,
                borderchars = borderchars,
                title = self.prompt_title,
            },
            results = {
                col = 2,
                line = 3,
                width = width - border,
                height = max_lines - prompt - border - 3,
                enter = false,
                border = true,
                borderchars = borderchars,
                title = "results",
            },
            preview = {
                col = 2 + width,
                line = 3,
                width = width - border - 1,
                height = max_lines - border - 1,
                enter = false,
                border = true,
                borderchars = borderchars,
                title = "preview",
            },
        }
    end
end

function M.setup()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    -- local defaults = laforge()

    require("telescope.pickers.layout_strategies").flex_aspect = flex_aspect_layout
    local defaults = {
        borderchars = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" },
        layout_strategy = "flex_aspect",
        scroll_strategy = "limit",
        path_display = { "truncate" },
    }

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

    vim.api.nvim_set_hl(0, "TelescopeSelection", { underline = true })
    vim.api.nvim_create_autocmd({ "InsertLeave" }, {
        pattern = { "*" },
        callback = function(event)
            if vim.bo[event.buf].filetype == "TelescopePrompt" then
                vim.api.nvim_set_hl(0, "TelescopeSelection", { standout = true })
            end
        end,
    })
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        pattern = { "*" },
        callback = function(event)
            if vim.bo[event.buf].filetype == "TelescopePrompt" then
                vim.api.nvim_set_hl(0, "TelescopeSelection", { bold = true })
            end
        end,
    })
end

function M.pick_resume()
    builtin.resume()
end

function M.pick_file()
    builtin.find_files()
end

function M.pick_file_config()
    builtin.find_files {
        prompt_title = "config files",
        search_dirs = { "~/src/fleet" },
        default_text = maybe_default_text(),
    }
end

function M.pick_file_home()
    builtin.find_files {
        prompt_title = "home files",
        search_dirs = { "~" },
        default_text = maybe_default_text(),
    }
end

function M.pick_file_nvim_config()
    -- NOTE this doesnt adapt to changes to rtp or packpath after startup
    -- TODO there is also nvim_get_runtime_file that could simulate exactly what nvim does? especially it can easily find all lua folders, or all ftplugin folders and things like that
    -- TODO use here current runtime, or dev environment? do we even want that enabled when in normal operation?
    -- TODO also a way to grep in all of vim source?
    builtin.find_files {
        prompt_title = "vim runtime",
        search_dirs = runtime_folders,
        default_text = maybe_default_text(),
    }
end

function M.pick_file_buffer_folder()
    local folder = assert(vim.fn.expand("%:h"), "no folder for current buffer")
    builtin.find_files { prompt_title = folder, search_dirs = { folder }, default_text = maybe_default_text() }
end

function M.pick_file_root()
    -- TODO somehow this kills telescope, too many files, wont update, wont filter, wont select, and after that vim is laggy, seems to keep things running in the background
    -- if we switch away from telescope then maybe we dont fix it here now
    builtin.find_files {
        prompt_title = "root files",
        search_dirs = { "/" },
        default_text = maybe_default_text(),
    }
end

function M.pick_jumplist()
    builtin.jumplist { initial_mode = "normal" }
end

function M.pick_file_git_diff()
    builtin.find_files {
        prompt_title = "files with diff",
        find_command = { "zsh", "-c", "git diff --name-only master 2>/dev/null || git diff --name-only main" },
        initial_mode = "normal",
        default_text = maybe_default_text(),
    }
end

function M.pick_grep()
    builtin.live_grep { default_text = maybe_default_text() }
end

function M.pick_buffer()
    builtin.buffers { default_text = maybe_default_text() }
end

function M.pick_references()
    builtin.lsp_references { initial_mode = "normal", default_text = maybe_default_text() }
end

function M.kinda_fuzzy_find_in_buffer()
    builtin.current_buffer_fuzzy_find { default_text = maybe_default_text("'") }
    -- alternative: builtin.current_buffer_fuzzy_find { fuzzy = false }
end

function M.pick_help()
    local default_text = maybe_default_text()

    -- TODO not sure how to handle things when we cancel things
    vim.cmd.enew() -- NOTE doesnt seem to leave unused unnamed buffers around, even thou I expected it to
    vim.bo.buftype = "help" -- NOTE documentation says dont do this, but no problem so far
    vim.bo.filetype = "help" -- not sure this is needed, or good?

    builtin.help_tags { default_text = default_text }
end

function M.pick_man()
    vim.cmd.enew()
    vim.bo.buftype = "nofile"
    vim.bo.filetype = "man"
    builtin.man_pages { sections = { "1", "4", "5", "7", "8" }, default_text = maybe_default_text() }
end
function M.pick_man_all()
    builtin.man_pages { sections = { "ALL" }, default_text = maybe_default_text() }
end

function M.pick_mark()
    builtin.marks { initial_mode = "normal" }
end

function M.pick_project_symbol()
    -- TODO make a filetype list with exceptions, just like for the snippets?
    if vim.bo.filetype == "python" then
        local ptags = require("ptags")
        -- TODO could we use a defined venv?
        -- should ptags itself be able to do that?
        local sources = {
            vim.fn.glob("python", false, true),
            vim.fn.glob("src", false, true),
            vim.fn.glob("libs/*/python", false, true),
        }
        sources = vim.iter(sources):flatten():totable()
        if #sources == 0 then
            sources = { "." }
        end
        ptags.telescope(sources, { attach_mappings = fn_mappings(at.top) })
    else
        builtin.lsp_dynamic_workspace_symbols { default_text = maybe_default_text() }
    end
end

function M.pick_buffer_symbol()
    -- TODO make a filetype list with exceptions, just like for the snippets?
    if vim.bo.filetype == "python" then
        local ptags = require("ptags")
        ptags.telescope({ vim.fn.expand("%") }, { attach_mappings = fn_mappings(at.top) })
    elseif vim.bo.filetype == "man" then
        -- TODO same for help files from vim? or are those text files? didnt know it only works in vim
        require("man").show_toc()
        vim.cmd([[wincmd c]])
        -- TODO to hide the filename? doesnt seem to work anymore
        builtin.loclist { fname_width = 0 }
    else
        -- TODO can be annoyingly slow, see https://github.com/nvim-telescope/telescope.nvim/issues/2274
        -- very shitty, and i tried to turn it around, but then the buf_request never calls the callback
        -- it should be possible to update with later picker:refresh(finder, opts), but it never gets there
        -- anyway lose telescope now?
        builtin.lsp_document_symbols { default_text = maybe_default_text() }
    end
end

function M.pick_buffer_diagnostic()
    -- TODO needed to set severity because of a bug, otherwise shows nothing, still true?
    -- see https://github.com/nvim-telescope/telescope.nvim/issues/2661
    builtin.diagnostics {
        initial_mode = "normal",
        bufnr = 0,
        severity_limit = vim.diagnostic.severity.ERROR,
        default_text = maybe_default_text(),
    }
end

function M.pick_buffer_diagnostic_all()
    builtin.diagnostics {
        initial_mode = "normal",
        bufnr = 0,
        severity_limit = vim.diagnostic.severity.HINT,
        default_text = maybe_default_text(),
    }
end

function M.pick_project_diagnostics()
    builtin.diagnostics {
        initial_mode = "normal",
        bufnr = nil,
        no_unlisted = false,
        severity_limit = vim.diagnostic.severity.ERROR,
        default_text = maybe_default_text(),
    }
end

function M.pick_project_diagnostics_all()
    builtin.diagnostics {
        initial_mode = "normal",
        bufnr = nil,
        no_unlisted = false,
        severity_limit = vim.diagnostic.severity.HINT,
        default_text = maybe_default_text(),
    }
end

return M
