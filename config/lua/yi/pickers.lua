local M = {}

local builtin_snack = require("snacks.picker")

---@param default? string
---@return string
local function maybe_default_text(default)
    if vim.api.nvim_get_mode().mode ~= "v" then
        return default or ""
    end
    vim.cmd([[normal! "ay]])
    return vim.fn.getreg("a")
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

function M.pick_diff_files()
    -- TODO maybe needs re-eval when review plugin lands
    local root = vim.fn.getcwd()
    local is_jj = vim.fn.isdirectory(root .. "/.jj") == 1
    if is_jj then
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
    builtin_snack.lines { search = maybe_default_text("'") }
end

function M.pick_help()
    builtin_snack.help { search = maybe_default_text() }
end

function M.pick_man()
    builtin_snack.man()
end

-- function M.pick_man_all()
--     -- TODO
-- end

function M.pick_mark()
    builtin_snack.marks()
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
