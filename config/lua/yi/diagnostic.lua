local M = {}

local function format_short(diagnostic)
    local icons = { "E", "W", "I", "H" }
    if diagnostic.code == nil then
        return icons[diagnostic.severity] .. " «" .. diagnostic.message .. "»"
    else
        return icons[diagnostic.severity] .. "=" .. diagnostic.code
    end
end

local function format_long(diagnostic)
    local icons = { "E", "W", "I", "H" }
    if diagnostic.code == nil then
        return icons[diagnostic.severity] .. " «" .. diagnostic.message .. "»"
    else
        return icons[diagnostic.severity] .. "=" .. diagnostic.code .. " «" .. diagnostic.message .. "»"
    end
end

function M.setup()
    local filter = { min = vim.diagnostic.severity.WARN }
    vim.diagnostic.config {
        underline = {
            severity = filter,
        },
        virtual_text = {
            severity = filter,
            prefix = "",
            format = format_short,
        },
        -- TODO this is cool for some other stuff for parentheses?
        -- virtual_lines = {
        --     severity = filter,
        --     current_line = true,
        --     format = format_long,
        -- },
        signs = true,
        update_in_insert = false,
        severity_sort = true,
        -- TODO jump? float?
        float = {
            -- prefix = function(diagnostic)
            --     local icons = { "E", "W", "I", "H" }
            --     if diagnostic.code == nil then
            --         return icons[diagnostic.severity]
            --     else
            --         return icons[diagnostic.severity] .. "=" .. diagnostic.code
            --     end
            -- end,
            -- format = function(diagnostic)
            --     return "«" .. diagnostic.message .. "»"
            -- end,
            suffix = function(diagnostic)
                local icons = { "E", "W", "I", "H" }
                if diagnostic.code == nil then
                    return "  [" .. icons[diagnostic.severity] .. "]"
                else
                    return "  [" .. icons[diagnostic.severity] .. "=" .. diagnostic.code .. "]"
                end
            end,
            border = "double",
            anchor_bias = "below",
        },
    }

    -- TODO this should be done with the theme?
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true })
end

local function old_highlights()
    -- TODO all hard-coded for https://github.com/morhetz/gruvbox#light-mode-1
    -- TODO or use the same icons as the lualine bottom right? lightbulb for hint, eg? trying
    vim.cmd([[
    " highlight DiagnosticFloatingError guifg=#3c3836
    highlight DiagnosticVirtualTextError guifg=#bdae93
    highlight DiagnosticUnderlineError gui=undercurl guisp=#cc241d
    highlight DiagnosticSignError guifg=#cc241d
    " sign define DiagnosticSignError text= texthl=DiagnosticSignError linehl= numhl=
    sign define DiagnosticSignError text=󰅚 texthl=DiagnosticSignError linehl= numhl=

    " highlight DiagnosticFloatingWarn guifg=#3c3836
    highlight DiagnosticVirtualTextWarn guifg=#bdae93
    highlight DiagnosticUnderlineWarn gui=undercurl guisp=#cc241d
    highlight DiagnosticSignWarn guifg=#cc241d
    " sign define DiagnosticSignWarn text= texthl=DiagnosticSignWarn linehl= numhl=
    sign define DiagnosticSignWarn text= texthl=DiagnosticSignWarn linehl= numhl=

    " highlight DiagnosticFloatingInfo guifg=#3c3836
    highlight DiagnosticVirtualTextInfo guifg=#bdae93
    highlight DiagnosticUnderlineInfo gui=underdotted guisp=#076678
    highlight DiagnosticSignInfo guifg=#076678
    " sign define DiagnosticSignInfo text= texthl=DiagnosticSignInfo linehl= numhl=
    sign define DiagnosticSignInfo text=󰋽 texthl=DiagnosticSignInfo linehl= numhl=

    " highlight DiagnosticFloatingHint guifg=#3c3836
    highlight DiagnosticVirtualTextHint guifg=#bdae93
    highlight DiagnosticUnderlineHint gui=underdotted guisp=#076678
    highlight DiagnosticSignHint guifg=#076678
    " sign define DiagnosticSignHint text= texthl=DiagnosticSignHint linehl= numhl=
    sign define DiagnosticSignHint text=󰛩 texthl=DiagnosticSignHint linehl= numhl=

    highlight LspSignatureActiveParameter gui=bold
]])
end

return M
