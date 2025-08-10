local M = {}

function M.setup()
    vim.cmd("syntax enable")

    vim.opt.background = "dark"
    vim.cmd("colorscheme nordfox")

    require("nvim-web-devicons").setup {}

    vim.cmd([[
        " hi CursorLine cterm=NONE ctermbg=1 ctermfg=NONE
        set cursorline nocursorcolumn
        augroup CursorLineOnlyInActiveWindow
          autocmd!
          autocmd VimEnter,WinEnter,BufWinEnter * setlocal cursorline nocursorcolumn
          autocmd WinLeave * setlocal nocursorline nocursorcolumn
        augroup END
    ]])

    -- local function window_nr()
    --     return "%#AlwaysOnWindowNumber#󰐤" .. vim.api.nvim_win_get_number(0)
    -- end

    ---@param bufnr number | nil bufnr
    local function diagnostic(bufnr)
        if #vim.lsp.get_clients { bufnr = bufnr } == 0 then
            return ""
        end

        local function num(severity)
            return #vim.diagnostic.get(bufnr, { severity = severity })
        end

        local s = vim.diagnostic.severity
        return num(s.ERROR) .. "e " .. num(s.WARN) .. "w"
    end

    local function lsp_busy()
        if #vim.lsp.get_clients { bufnr = nil } == 0 then
            return ""
        else
            if #vim.lsp.status() == 0 then
                return "idle"
            end
            return "busy"
        end
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

    require("lualine").setup {
        options = {
            theme = "nightfox",
            icons_enabled = false,
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            always_divide_middle = true,
            globalstatus = false,
        },
        sections = {
            lualine_a = { "mode", show_file },
            -- lualine_a = { window_nr, show_file },
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            -- lualine_y = { { "diagnostics", sources = { "nvim_lsp" }, colored = false } },
            lualine_y = {
                {
                    function()
                        return diagnostic(0)
                    end,
                },
            },
            lualine_z = {
                { "filetype", icons_enabled = false },
                "location",
            },
        },
        inactive_sections = {
            lualine_a = { show_file },
            -- lualine_a = { window_nr, show_file },
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
        },
        tabline = {
            lualine_a = {
                {
                    "tabs",
                    max_length = vim.o.columns,
                    show_modified_status = false,
                },
            },
            lualine_y = {
                function()
                    return diagnostic(nil)
                end,
            },
            lualine_z = {
                function()
                    return lsp_busy()
                end,
            },
        },
        extensions = {},
    }
end

return M
