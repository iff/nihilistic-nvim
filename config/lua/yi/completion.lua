local M = {}

function M.setup()
    require("blink.cmp").setup {
        cmdline = {
            completion = {
                menu = {
                    auto_show = false,
                },
                list = {
                    selection = { preselect = false },
                },
            },
        },
        completion = {
            trigger = {
                prefetch_on_insert = false,
                show_on_insert_on_trigger_character = false,
                show_in_snippet = false,
            },
            accept = {
                dot_repeat = false,
            },
            menu = {
                auto_show = false,
                border = "rounded",
                max_height = 20,
            },
            documentation = {
                auto_show = true,
                window = { border = "rounded", max_height = 20 },
            },
            list = {
                selection = { preselect = false },
            },
            ghost_text = { enabled = true },
        },
        keymap = {
            preset = "none",
            ["<c-e>"] = { "select_next", "fallback" },
            ["<c-u>"] = { "select_prev", "fallback" },
            ["<c-y>"] = { "hide", "fallback" },
            ["<enter>"] = { "accept", "fallback" },
            ["<c-n>"] = { "show", "fallback" },
            ["<tab>"] = { "snippet_forward", "fallback" },
        },
        sources = {
            default = { "lsp", "snippets" },
        },
        snippets = {
            preset = "default",
        },
        fuzzy = { implementation = "prefer_rust" }, -- TODO get from nix
        -- TODO also has signature bindings
    }
end

function M.complete_full()
    require("blink.cmp").show()
end

function M.get_capabilities()
    return require("blink.cmp").get_lsp_capabilities()
end

---@param id integer
---@return string
local function kind_from_id(id)
    -- see https://github.com/microsoft/language-server-protocol/blob/gh-pages/_specifications/lsp/3.18/language/completion.md
    local spec = {
        [1] = "Text",
        [2] = "Method",
        [3] = "Function",
        [4] = "Constructor",
        [5] = "Field",
        [6] = "Variable",
        [7] = "Class",
        [8] = "Interface",
        [9] = "Module",
        [10] = "Property",
        [11] = "Unit",
        [12] = "Value",
        [13] = "Enum",
        [14] = "Keyword",
        [15] = "Snippet",
        [16] = "Color",
        [17] = "File",
        [18] = "Reference",
        [19] = "Folder",
        [20] = "EnumMember",
        [21] = "Constant",
        [22] = "Struct",
        [23] = "Event",
        [24] = "Operator",
        [25] = "TypeParameter",
    }
    return spec[id] or tostring(id)
end

local function apply_completion(item)
    -- its a bit sad that we have to replicate code from nvim-cpm/blink here
    -- decided to only support textEdit protocol
    -- see https://github.com/microsoft/language-server-protocol/blob/gh-pages/_specifications/lsp/3.18/language/completion.md
    if item.textEdit then
        local text_edit = item.textEdit
        local new_text = text_edit.newText
        local range = text_edit.replace or text_edit.range

        if range then
            local start_line = range["start"].line
            local start_col = range["start"].character
            local end_line = range["end"].line
            local end_col = range["end"].character

            -- insertTextFormat: 2 => snipped, 1 => plain text
            if item.insertTextFormat == 2 then
                vim.api.nvim_buf_set_text(0, start_line, start_col, end_line, end_col, {})
                vim.api.nvim_win_set_cursor(0, { start_line + 1, start_col })
                vim.snippet.expand(new_text)
            else
                local l = vim.split(new_text, "\n")
                vim.api.nvim_buf_set_text(0, start_line, start_col, end_line, end_col, l)
                -- TODO not sure this is correct :)
                local new_end_line = start_line + #l - 1
                local new_end_col = #l[#l]
                if #l == 1 then
                    new_end_col = start_col + #l[1]
                end
                vim.api.nvim_win_set_cursor(0, { new_end_line + 1, new_end_col })
            end
        elseif item.insertTextFormat == 2 then
            vim.snippet.expand(new_text)
        else
            vim.api.nvim_put({ new_text }, "c", false, true)
        end
    elseif item.insertText then
        assert(false, "insertText completion not supported, expected textEdit")
    elseif item.label then
        vim.api.nvim_put({ item.label }, "c", false, true)
    else
        assert(false, "item seems to be missing completion information")
    end
end

--- open the completion items in a snacks picker and select there with fuzzy matching
function M.complete_select()
    -- TODO this is only lazy failsafe
    local client = assert(require("yi.lsp").get_one_lsp_client(), "no lsp client")
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    local replies, error = client:request_sync("textDocument/completion", params, 5000, 0)
    assert(not error, "lsp request error")
    -- vim.print { replies = replies, error = error }
    local result = assert((replies or {}).result, "lsp request error")

    local items = vim.tbl_map(function(entry)
        return {
            text = entry.label,
            entry = entry,
        }
    end, result.items)

    require("snacks.picker").pick {
        title = "completion",
        items = items,
        format = function(item)
            return {
                { item.entry.label },
                { " [" .. kind_from_id(item.entry.kind) .. "]", "SnacksPickerComment" },
            }
        end,
        preview = function(ctx)
            local entry = ctx.item.entry
            local lines = {}
            if entry.detail then
                vim.list_extend(lines, vim.split(entry.detail, "\n"))
            end
            local doc = entry.documentation
            if doc then
                if #lines > 0 then
                    table.insert(lines, "")
                end
                vim.list_extend(lines, vim.split(type(doc) == "table" and doc.value or doc, "\n"))
            end
            vim.bo[ctx.buf].modifiable = true
            vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
            vim.bo[ctx.buf].filetype = "markdown"
        end,
        confirm = function(picker, item)
            picker:close()
            apply_completion(item.entry)
        end,
        on_close = function()
            vim.schedule(function()
                vim.cmd.startinsert {}
            end)
        end,
    }
end

return M
