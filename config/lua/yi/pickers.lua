local M = {}

local builtin_snack = require("snacks.picker")

local exclude = { ".git", "uv.lock", "flake.lock", "cargo.lock", "npm.lock" }

---@param default? string
---@return string
local function maybe_default_text(default)
    if vim.api.nvim_get_mode().mode ~= "v" then
        return default or ""
    end
    vim.cmd([[normal! "ay]])
    return vim.fn.getreg("a")
end

local function fn_normal()
    vim.cmd("stopinsert")
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
                        fullscreen = true,
                        { win = "preview" },
                        { win = "list", height = 7 },
                        { win = "input", height = 1 },
                    },
                },
                wide = {
                    reverse = true,
                    layout = {
                        box = "horizontal",
                        fullscreen = true,
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
            formatters = { file = { filename_first = true, truncate = "left", icon_width = 3 } },
            win = {
                input = {
                    border = heavy,
                    wo = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder" },
                    keys = {
                        ["<c-e>"] = { "list_down", mode = { "i", "n" } },
                        ["<c-u>"] = { "list_up", mode = { "i", "n" } },
                        [" "] = { "flash", mode = "n" },
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
            actions = {
                flash = function(picker)
                    require("flash").jump {
                        pattern = "^",
                        label = { after = { 0, 0 } },
                        search = {
                            mode = "search",
                            exclude = {
                                function(win)
                                    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                                end,
                            },
                        },
                        action = function(match)
                            local idx = picker.list:row2idx(match.pos[1])
                            picker.list:_move(idx, true, true)
                        end,
                    }
                end,
            },
        },
    }
end

function M.pick_resume()
    builtin_snack.resume()
end

function M.pick_file()
    builtin_snack.files {
        cmd = "fd",
        hidden = true,
        exclude = exclude,
        search = maybe_default_text(),
    }
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
    builtin_snack.files { title = "vim runtime", dirs = { "~/src/nihilistic-nvim" }, search = maybe_default_text() }
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

function M.pick_qflist()
    builtin_snack.qflist()
end

function M.pick_diff_files()
    -- TODO maybe needs re-eval when review plugin lands
    if require("yi.vcs").jj_root() then
        -- TODO only shows diff of current commit
        require("jj.picker").status()
    else
        builtin_snack.files {
            title = "files with diff",
            cmd = is_jj and { "jj", "diff", "--name-only", "-r", "trunk()..@" }
                or { "zsh", "-c", "git diff --name-only master 2>/dev/null || git diff --name-only main" },
            search = maybe_default_text(),
        }
    end
end

function M.pick_conflicts()
    if require("yi.vcs").jj_root() then
        require("jj.picker").conflict()
    end
end

function M.pick_grep()
    builtin_snack.grep {
        search = maybe_default_text(),
        command = "rg",
        exclude = exclude,
    }
end

function M.pick_buffer()
    builtin_snack.buffers { pattern = maybe_default_text(), sort_lastuse = true, hidden = false, nofile = false }
end

function M.pick_references()
    builtin_snack.lsp_references { pattern = maybe_default_text() }
end

function M.kinda_fuzzy_find_in_buffer()
    builtin_snack.lines { pattern = maybe_default_text("'") }
end

function M.pick_help()
    builtin_snack.help {
        pattern = maybe_default_text(),
        confirm = function(picker, item)
            picker:close()
            vim.cmd.enew() -- doesnt seem to leave unused unnamed buffers around, even thou I expected it to
            vim.bo.buftype = "help" -- documentation says dont do this, but no problem so far
            vim.bo.filetype = "help" -- not sure this is needed, or good?
            picker:action("help", item)
        end,
    }
end

function M.pick_man()
    -- TODO used to have: sections = { "1", "4", "5", "7", "8" }
    builtin_snack.man {
        pattern = maybe_default_text(),
        confirm = function(picker, item, action)
            picker:close()
            vim.schedule(function()
                vim.cmd.enew()
                vim.bo.buftype = "nofile"
                vim.bo.filetype = "man"
                local cmd = "Man " .. item.ref ---@type string
                vim.cmd(cmd)
            end)
        end,
    }
end

-- function M.pick_man_all()
--     -- TODO
-- end

function M.pick_mark()
    builtin_snack.marks {
        pattern = maybe_default_text(),
        on_show = fn_normal,
        win = {
            input = {
                keys = {
                    ["d"] = { "mark_delete", mode = "n" },
                },
            },
        },
    }
end

function M.pick_project_symbol()
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

function M.pick_buffer_symbol()
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
            pattern = maybe_default_text(),
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
    builtin_snack.treesitter {
        pattern = maybe_default_text(),
        keep_parents = true,
    }
end

function M.pick_command_history()
    builtin_snack.command_history {
        pattern = maybe_default_text(),
    }
end

function M.pick_undo()
    builtin_snack.undo {
        on_show = fn_normal,
    }
end

return M
