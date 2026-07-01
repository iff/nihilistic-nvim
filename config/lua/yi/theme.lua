local M = {}

function M.palette()
    return require("nightfox.palette").load(vim.g.colors_name or "nordfox")
end

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

---@param bufnr integer | nil
local function combined_diagnostics(bufnr)
    if #vim.lsp.get_clients { bufnr = bufnr } == 0 then
        return ""
    end

    local function num(severity)
        local loc = #vim.diagnostic.get(0, { severity = severity })
        local all = #vim.diagnostic.get(nil, { severity = severity })
        return loc .. "/" .. all
    end

    local s = vim.diagnostic.severity
    return "%#DiagnosticError#󰅚 " .. num(s.ERROR) .. " %#DiagnosticWarn#󰀪 " .. num(s.WARN)
end

function M.setup_tabline()
    local function setup_hls(pal)
        vim.api.nvim_set_hl(0, "StatusLine", { bg = pal.bg1, fg = pal.bg0 })
        vim.api.nvim_set_hl(0, "StatusLineNC", { bg = pal.bg1, fg = pal.bg0 })
        vim.api.nvim_set_hl(0, "TabLine", { bg = pal.bg0, fg = pal.fg3, bold = true })
        vim.api.nvim_set_hl(0, "TabLineSel", { bg = pal.bg0, fg = pal.fg1, bold = true })
        vim.api.nvim_set_hl(0, "TabLineFill", { bg = pal.bg0 })
        vim.api.nvim_set_hl(0, "TablineModeN", { bg = pal.bg0, fg = pal.blue.base, bold = true })
        vim.api.nvim_set_hl(0, "TablineModeI", { bg = pal.bg0, fg = pal.green.base, bold = true })
        vim.api.nvim_set_hl(0, "TablineModeV", { bg = pal.bg0, fg = pal.magenta.base, bold = true })
        vim.api.nvim_set_hl(0, "TablineModeR", { bg = pal.bg0, fg = pal.red.base, bold = true })
        vim.api.nvim_set_hl(0, "TablineModeC", { bg = pal.bg0, fg = pal.yellow.base, bold = true })
        vim.api.nvim_set_hl(0, "TablineItem", { bg = pal.bg0, fg = pal.fg2, bold = true })
    end
    setup_hls(M.palette())

    local mode_hls = {
        n = "TablineModeN",
        i = "TablineModeI",
        v = "TablineModeV",
        V = "TablineModeV",
        R = "TablineModeR",
        c = "TablineModeC",
    }

    local current_mode_hl = "TablineModeN"

    local function tabline()
        local mode_hl = current_mode_hl
        local parts = {}

        table.insert(parts, "%#" .. mode_hl .. "# " .. map_mode() .. " ")

        local cur = vim.api.nvim_get_current_tabpage()
        for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            local nr = vim.api.nvim_tabpage_get_number(tab)
            if tab == cur then
                table.insert(parts, "%#TabLineSel# " .. nr .. " ")
            else
                table.insert(parts, "%#TablineItem# " .. nr .. " ")
            end
        end

        table.insert(parts, "%#TabLineFill#%=")

        local diag = combined_diagnostics(nil)
        if diag ~= "" then
            table.insert(parts, diag .. " ")
        end

        local ft = vim.bo.filetype
        if ft ~= "" then
            table.insert(parts, "%#TablineItem# " .. ft .. " ")
        end

        return table.concat(parts)
    end

    M.tabline = tabline
    vim.o.tabline = "%!v:lua.require('yi.theme').tabline()"
    vim.o.showtabline = 2

    M.statusline = function()
        return string.rep("─", vim.api.nvim_win_get_width(0))
    end
    vim.o.statusline = "%!v:lua.require('yi.theme').statusline()"
    vim.o.laststatus = 0

    vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function()
            vim.cmd("redrawtabline")
        end,
    })
    vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*:*",
        callback = function()
            current_mode_hl = mode_hls[vim.api.nvim_get_mode().mode] or "TablineModeN"
            vim.cmd("redrawtabline")
        end,
    })
    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
            setup_hls(M.palette())
        end,
    })
end

-- function M.setup_lualine()
--     ---@param bufnr integer | nil bufnr
--     local function diagnostic(bufnr)
--         if #vim.lsp.get_clients { bufnr = bufnr } == 0 then
--             return ""
--         end
--
--         local function num(severity)
--             return #vim.diagnostic.get(bufnr, { severity = severity })
--         end
--
--         local s = vim.diagnostic.severity
--         return "%#DiagnosticError#󰅚 " .. num(s.ERROR) .. " %#DiagnosticWarn#󰀪 " .. num(s.WARN)
--     end
--
--     local function show_file()
--         local file_icons = {
--             modified = "",
--             unmodified = "󰈖",
--             read_only = "",
--             autosave = "",
--             no_autosave = " ",
--         }
--
--         local icon = nil
--         if vim.bo.modifiable then
--             if vim.bo.modified then
--                 icon = file_icons.modified
--             else
--                 icon = file_icons.unmodified
--             end
--         else
--             icon = file_icons.read_only
--         end
--
--         local autosave = nil
--         if vim.b.autosave == true then
--             autosave = file_icons.autosave
--         else
--             autosave = file_icons.no_autosave
--         end
--
--         local name = vim.api.nvim_buf_get_name(0)
--         local protocol = string.match(name, "^(.+)://")
--         if protocol == nil then
--         elseif protocol == "fugitive" then
--             local summary = string.match(name, "git//$")
--             local at = string.match(name, "git//(%w+)/")
--             if summary ~= nil then
--                 protocol = protocol .. "@summary"
--             elseif at ~= nil then
--                 protocol = protocol .. "@" .. string.sub(at, 1, 7)
--             else
--                 protocol = protocol .. "@?"
--             end
--         else
--             protocol = protocol .. "?"
--         end
--
--         if protocol == nil then
--             protocol = ""
--         else
--             protocol = protocol .. "://"
--         end
--
--         return icon .. autosave .. " " .. protocol .. "%t"
--     end
--
--     local function lualine_theme()
--         local pal = M.palette()
--         local bg = pal.bg0
--         local function section(fg)
--             return { bg = bg, fg = fg, gui = "bold" }
--         end
--         return {
--             normal = { a = section(pal.blue.base), b = section(pal.fg2), c = section(pal.fg2) },
--             insert = { a = section(pal.green.base), b = section(pal.fg2), c = section(pal.fg2) },
--             visual = { a = section(pal.magenta.base), b = section(pal.fg2), c = section(pal.fg2) },
--             replace = { a = section(pal.red.base), b = section(pal.fg2), c = section(pal.fg2) },
--             command = { a = section(pal.yellow.base), b = section(pal.fg2), c = section(pal.fg2) },
--             inactive = { a = section(pal.fg3), b = section(pal.fg3), c = section(pal.fg3) },
--         }
--     end
--
--     require("lualine").setup {
--         options = {
--             theme = lualine_theme(),
--             icons_enabled = false,
--             component_separators = { left = "", right = "" },
--             -- section_separators = { left = "", right = "" },
--             section_separators = { left = "", right = "" },
--             always_divide_middle = true,
--             globalstatus = false,
--         },
--         sections = {
--             lualine_a = {
--                 -- "mode"
--             },
--             lualine_b = {
--                 -- show_file,
--             },
--             lualine_c = {},
--             lualine_x = {},
--             lualine_y = {
--                 {
--                     -- function()
--                     --     return diagnostic(0)
--                     -- end,
--                 },
--             },
--             lualine_z = {
--                 -- "location",
--             },
--         },
--         inactive_sections = {
--             lualine_a = {
--                 -- show_file,
--             },
--             lualine_b = {},
--             lualine_c = {},
--             lualine_x = {},
--             lualine_y = {},
--             lualine_z = {},
--         },
--         tabline = {
--             lualine_a = {
--                 -- TODO do I really use this?
--                 map_mode,
--             },
--             lualine_b = {
--                 -- TODO not sure, I almost never use tabs
--                 {
--                     "tabs",
--                     max_length = vim.o.columns,
--                     show_modified_status = false,
--                 },
--             },
--             lualine_c = {},
--             lualine_x = {},
--             lualine_y = {
--                 function()
--                     -- return diagnostic(nil)
--                     return combined_diagnostics(nil)
--                 end,
--             },
--             lualine_z = {
--                 { "filetype", icons_enabled = false },
--             },
--         },
--         extensions = {},
--     }
--
--     vim.o.laststatus = 0
--     vim.api.nvim_create_autocmd("WinNew", {
--         callback = function()
--             vim.o.laststatus = 0
--         end,
--     })
-- end

function M.setup()
    vim.cmd("syntax enable")

    vim.opt.background = "dark"
    vim.cmd("colorscheme nordfox")

    vim.api.nvim_create_user_command("SwTheme", function()
        local name = vim.g.colors_name --[[@as string]]
        if name == "nordfox" then
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

    require("fidget").setup {}

    M.setup_tabline()
    -- M.setup_lualine()
end

return M
