local M = {}

local builtin = require("telescope.builtin")
local builtin_snack = require("snacks.picker")

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
                width = max_columns - border - 1,
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
    local heavy = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" }
    require("snacks").setup {
        picker = {
            ui_select = true,
            show_delay = 0,
            layouts = {
                narrow = {
                    reverse = true,
                    layout = {
                        box = "vertical",
                        width = 0.999,
                        height = 0.999,
                        { win = "preview" },
                        { win = "list", height = 7 },
                        { win = "input", height = 1 },
                    },
                },
                wide = {
                    reverse = true,
                    layout = {
                        box = "horizontal",
                        width = 0.999,
                        height = 0.999,
                        {
                            box = "vertical",
                            { win = "list" },
                            { win = "input", height = 1 },
                        },
                        { win = "preview" },
                    },
                },
            },
            layout = function()
                -- NOTE 190 cols is aligned with when lavish-layout switches in dynamic mode
                return vim.o.columns > 190 and "wide" or "narrow"
            end,
            win = {
                input = {
                    border = heavy,
                    wo = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder" },
                    keys = {
                        ["<c-e>"] = { "list_down", mode = { "i", "n" } },
                        ["<c-u>"] = { "list_up", mode = { "i", "n" } },
                    },
                },
                list = {
                    border = heavy,
                    wo = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:CursorLine" },
                },
                preview = {
                    border = heavy,
                    wo = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder" },
                },
            },
        },
    }

    local telescope = require("telescope")
    local actions = require("telescope.actions")

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
    builtin_snack.resume()
end

function M.pick_file()
    builtin_snack.files()
end

function M.pick_file_notes()
    builtin_snack.files { title = "notes", dirs = { "~/src/notes" }, search = maybe_default_text() }
end

function M.pick_file_config()
    builtin_snack.files { title = "config files", dirs = { "~/src/fleet" }, search = maybe_default_text() }
end

function M.pick_file_home()
    builtin_snack.files { title = "home files", dirs = { "~" }, search = maybe_default_text() }
end

function M.pick_file_nvim_config()
    -- NOTE this doesnt adapt to changes to rtp or packpath after startup
    -- TODO there is also nvim_get_runtime_file that could simulate exactly what nvim does? especially it can easily find all lua folders, or all ftplugin folders and things like that
    -- TODO use here current runtime, or dev environment? do we even want that enabled when in normal operation?
    -- TODO also a way to grep in all of vim source?
    -- builtin.find_files { prompt_title = "vim runtime", search_dirs = runtime_folders, default_text = maybe_default_text() }
    builtin_snack.files { title = "vim runtime", dirs = runtime_folders, search = maybe_default_text() }
end

function M.pick_file_buffer_folder()
    local folder = assert(vim.fn.expand("%:h"), "no folder for current buffer")
    builtin_snack.files { title = folder, dirs = { folder }, search = maybe_default_text() }
end

-- function M.pick_file_root()
--     builtin_snack.files { title = "root files", dirs = { "/" }, search = maybe_default_text() }
-- end

function M.pick_jumplist()
    builtin_snack.jumps()
end

function M.pick_diff_files()
    -- TODO better check?
    local root = vim.fn.getcwd()
    local is_jj = vim.fn.isdirectory(root .. "/.jj") == 1
    builtin.find_files {
        prompt_title = "files with diff",
        find_command = is_jj and { "jj", "diff", "--name-only", "-r", "trunk()..@" }
            or { "zsh", "-c", "git diff --name-only master 2>/dev/null || git diff --name-only main" },
        initial_mode = "normal",
        default_text = maybe_default_text(),
    }
end

function M.pick_grep()
    builtin_snack.grep { search = maybe_default_text() }
end

function M.pick_buffer()
    builtin_snack.buffers { search = maybe_default_text() }
end

function M.pick_references()
    builtin_snack.lsp_references()
end

function M.kinda_fuzzy_find_in_buffer()
    -- builtin.current_buffer_fuzzy_find { default_text = maybe_default_text("'") }
    -- alternative: builtin.current_buffer_fuzzy_find { fuzzy = false }
    builtin_snack.lines { search = maybe_default_text("'") }
end

function M.pick_help()
    -- TODO not sure how to handle things when we cancel things
    -- vim.cmd.enew() -- NOTE doesnt seem to leave unused unnamed buffers around, even thou I expected it to
    -- vim.bo.buftype = "help" -- NOTE documentation says dont do this, but no problem so far
    -- vim.bo.filetype = "help" -- not sure this is needed, or good?
    -- builtin.help_tags { default_text = maybe_default_text() }
    builtin_snack.help { search = maybe_default_text() }
end

function M.pick_man()
    -- TODO snacks.picker.man fails because man -k .
    vim.cmd.enew()
    vim.bo.buftype = "nofile"
    vim.bo.filetype = "man"
    builtin.man_pages { sections = { "1", "4", "5", "7", "8" }, default_text = maybe_default_text() }
end

function M.pick_man_all()
    builtin.man_pages { sections = { "ALL" }, default_text = maybe_default_text() }
end

function M.pick_mark()
    builtin_snack.marks()
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
        -- builtin.lsp_dynamic_workspace_symbols { default_text = maybe_default_text() }

        -- NOTE the query is sent as-is to the LSP -> no fuzzy matching which is a pitty
        -- does Telescope populate a table with "all" symbols? could we do the same here?
        builtin_snack.lsp_symbols {
            workspace = true,
            live = true,
            -- tree = true,
            -- keep_parents = true,
            search = maybe_default_text(),
            filter = {
                default = {
                    "Class",
                    "Constructor",
                    "Enum",
                    "Field",
                    "Function",
                    "Interface",
                    "Method",
                    "Module",
                    "Namespace",
                    "Package",
                    "Property",
                    "Struct",
                    "Trait",
                },
            },
        }
    end
end

function M.pick_buffer_symbol()
    -- TODO ptags needs snack.pickers
    -- TODO make a filetype list with exceptions, just like for the snippets?
    -- if vim.bo.filetype == "python" then
    --     local ptags = require("ptags")
    --     ptags.telescope({ vim.fn.expand("%") }, { attach_mappings = fn_mappings(at.top) })
    -- elseif vim.bo.filetype == "man" then
    if vim.bo.filetype == "man" then
        -- TODO same for help files from vim? or are those text files? didnt know it only works in vim
        require("man").show_toc()
        vim.cmd([[wincmd c]])
        -- TODO to hide the filename? doesnt seem to work anymore
        -- builtin.loclist { fname_width = 0 }
        builtin_snack.loclist()
    else
        builtin_snack.lsp_symbols {
            tree = true,
            keep_parents = true,
            search = maybe_default_text(),
            filter = {
                default = {
                    "Variable",
                    "Class",
                    "Constructor",
                    "Enum",
                    "Field",
                    "Function",
                    "Interface",
                    "Method",
                    "Module",
                    "Namespace",
                    "Package",
                    "Property",
                    "Struct",
                    "Trait",
                },
            },
        }
    end
end

function M.pick_buffer_diagnostics()
    builtin_snack.diagnostics_buffer { severity = { min = vim.diagnostic.severity.ERROR } }
end

function M.pick_buffer_diagnostics_all()
    builtin_snack.diagnostics_buffer()
end

function M.pick_project_diagnostics()
    builtin_snack.diagnostics { severity = { min = vim.diagnostic.severity.ERROR } }
end

function M.pick_project_diagnostics_all()
    builtin_snack.diagnostics()
end

function M.pick_treesitter()
    builtin_snack.treesitter()
end

return M
