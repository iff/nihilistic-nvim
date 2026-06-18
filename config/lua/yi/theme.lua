local M = {}

function M.palette()
    return require("nightfox.palette").load(vim.g.colors_name or "nordfox")
end

function M.setup()
    vim.cmd("syntax enable")

    vim.opt.background = "dark"
    vim.cmd("colorscheme nordfox")

    vim.api.nvim_create_user_command("SwTheme", function()
        if vim.g.colors_name == "nordfox" then
            vim.opt.background = "light"
            vim.cmd("colorscheme dayfox")
        else
            vim.opt.background = "dark"
            vim.cmd("colorscheme nordfox")
        end
    end, {})

    -- require("nvim-web-devicons").setup {}
    require("mini.icons").setup {
        style = "glyph",
    }

    -- set cursor line bg in active window to palette bg2
    local pal = M.palette()
    vim.api.nvim_set_hl(0, "CursorLine", { bg = pal.bg2 })
    vim.opt.cursorline = false
    vim.opt.cursorcolumn = false
    vim.api.nvim_create_augroup("CursorLineOnlyInActiveWindow", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
        group = "CursorLineOnlyInActiveWindow",
        callback = function()
            local win = vim.api.nvim_get_current_win()
            vim.opt_local.cursorline = true
            vim.opt_local.cursorcolumn = false
            vim.defer_fn(function()
                if vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() == win then
                    vim.wo[win].cursorline = false
                end
            end, 800)
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = "CursorLineOnlyInActiveWindow",
        callback = function()
            vim.opt_local.cursorline = false
            vim.opt_local.cursorcolumn = false
        end,
    })

    ---@param bufnr number | nil bufnr
    local function diagnostic(bufnr)
        if #vim.lsp.get_clients { bufnr = bufnr } == 0 then
            return ""
        end

        local function num(severity)
            return #vim.diagnostic.get(bufnr, { severity = severity })
        end

        local s = vim.diagnostic.severity
        return "%#DiagnosticError#󰅚 " .. num(s.ERROR) .. " %#DiagnosticWarn#󰀪 " .. num(s.WARN)
    end

    -- local function lsp_busy()
    --     if #vim.lsp.get_clients { bufnr = nil } == 0 then
    --         return ""
    --     else
    --         if #vim.lsp.status() == 0 then
    --             return "idle"
    --         end
    --         return "busy"
    --     end
    -- end

    local function map_mode()
        local mappings = require("yi.mappings")
        local icons = {
            default = "",
            search = "",
            treesitter = "󰔱",
            windows = "󱂬",
            shifts = "",
            diagnostic = "",
        }
        return icons[mappings.mode] or mappings.mode
    end

    local function show_file()
        local file_icons = {
            modified = "",
            unmodified = "󰈖",
            read_only = "",
            autosave = "",
            no_autosave = " ",
        }

        local icon = nil
        if vim.bo.modifiable then
            if vim.bo.modified then
                icon = file_icons.modified
            else
                icon = file_icons.unmodified
            end
        else
            icon = file_icons.read_only
        end

        local autosave = nil
        if vim.b.autosave == true then
            autosave = file_icons.autosave
        else
            autosave = file_icons.no_autosave
        end

        local name = vim.api.nvim_buf_get_name(0)
        local protocol = string.match(name, "^(.+)://")
        if protocol == nil then
        elseif protocol == "fugitive" then
            -- (fugitive summary)
            local summary = string.match(name, "git//$")
            -- (at commit, thats always [index] in a diff?)
            local at = string.match(name, "git//(%w+)/")
            if summary ~= nil then
                protocol = protocol .. "@summary"
            elseif at ~= nil then
                protocol = protocol .. "@" .. string.sub(at, 1, 7)
            else
                protocol = protocol .. "@?"
            end
        else
            protocol = protocol .. "?"
        end

        if protocol == nil then
            protocol = ""
        else
            protocol = protocol .. "://"
        end

        return icon .. autosave .. " " .. protocol .. "%t"
    end

    require("fidget").setup {}

    local function lualine_theme()
        local pal = M.palette()
        local bg = pal.bg0
        local function section(fg)
            return { bg = bg, fg = fg, gui = "bold" }
        end
        return {
            normal = { a = section(pal.blue.base), b = section(pal.fg2), c = section(pal.fg2) },
            insert = { a = section(pal.green.base), b = section(pal.fg2), c = section(pal.fg2) },
            visual = { a = section(pal.magenta.base), b = section(pal.fg2), c = section(pal.fg2) },
            replace = { a = section(pal.red.base), b = section(pal.fg2), c = section(pal.fg2) },
            command = { a = section(pal.yellow.base), b = section(pal.fg2), c = section(pal.fg2) },
            inactive = { a = section(pal.fg3), b = section(pal.fg3), c = section(pal.fg3) },
        }
    end

    require("lualine").setup {
        options = {
            theme = lualine_theme(),
            icons_enabled = false,
            component_separators = { left = "", right = "" },
            -- section_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            always_divide_middle = true,
            globalstatus = false,
        },
        sections = {
            lualine_a = {
                -- "mode"
            },
            lualine_b = {
                -- show_file,
            },
            lualine_c = {},
            lualine_x = {},
            lualine_y = {
                {
                    function()
                        return diagnostic(0)
                    end,
                },
            },
            lualine_z = {
                "location",
            },
        },
        inactive_sections = {
            lualine_a = {
                show_file,
            },
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
        },
        tabline = {
            lualine_a = {
                -- TODO do I really use this?
                map_mode,
            },
            lualine_b = {
                -- TODO not sure, I almost never use tabs
                {
                    "tabs",
                    max_length = vim.o.columns,
                    show_modified_status = false,
                },
            },
            lualine_c = {},
            lualine_x = {},
            lualine_y = {
                function()
                    return diagnostic(nil)
                end,
            },
            lualine_z = {
                { "filetype", icons_enabled = false },
            },
        },
        extensions = {},
    }
end

return M
