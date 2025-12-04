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
    M.config(false)

    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true })
    vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { undercurl = true })
end

---@type boolean
M.virtual_lines_enabled = false

---@param enable_virtual_lines boolean
function M.config(enable_virtual_lines)
    local filter = { min = vim.diagnostic.severity.HINT }
    M.virtual_lines_enabled = enable_virtual_lines
    local virtual_text, virtual_lines
    if enable_virtual_lines then
        virtual_text = false
        virtual_lines = {
            severity = filter,
            current_line = false,
            format = format_long,
        }
    else
        virtual_text = {
            severity = filter,
            prefix = "",
            format = format_short,
        }
        virtual_lines = false
    end
    vim.diagnostic.config {
        underline = {
            severity = filter,
        },
        virtual_text = virtual_text,
        virtual_lines = virtual_lines,
        signs = true,
        update_in_insert = false,
        severity_sort = true,
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
                    return "  [" .. icons[diagnostic.severity] .. "]", ""
                else
                    return "  [" .. icons[diagnostic.severity] .. "=" .. diagnostic.code .. "]", ""
                end
            end,
            border = "double",
            anchor_bias = "below",
        },
    }
end

function M.toggle_virtual_lines()
    local before = vim.fn.winline()

    M.config(not M.virtual_lines_enabled)

    -- NOTE if the lsp is slow, no virtual lines have been added yet, and we dont counteract the move
    -- but they will pop in later and things will jump
    local after = vim.fn.winline()
    local move = -after + before

    if move > 0 then
        vim.cmd([[exe "normal! ]] .. move .. [[\<c-y>"]])
    end

    if move < 0 then
        vim.cmd([[exe "normal! ]] .. -move .. [[\<c-e>"]])
    end
end

return M
