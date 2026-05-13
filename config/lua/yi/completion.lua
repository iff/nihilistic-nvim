local M = {}

function M.setup()
    require("blink.cmp").setup {
        completion = {
            trigger = {
                prefetch_on_insert = false,
                show_on_insert_on_trigger_character = false,
            },
            menu = {
                auto_show = false,
                border = "double",
                max_height = 20,
            },
            documentation = {
                auto_show = true,
                window = { border = "double", max_height = 20 },
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
    -- see https://github.com/microsoft/language-server-protocol/blob/gh-pages/_specifications/lsp/3.18/language/completion.md
    -- vim.print(item)
    if item.textEdit then
        local text_edit = item.textEdit
        local new_text = text_edit.newText
        local range = text_edit.replace or text_edit.range

        if range then
            local start_line = range["start"].line
            local start_col = range["start"].character
            local end_line = range["end"].line
            local end_col = range["end"].character

            -- NOTE most of the time text will not contain newlines for comp?
            local l = vim.split(new_text, "\n")
            assert(#l == 1, "only newText without newlines supported atm")
            -- TODO mostly we will be in the case where start = end
            vim.api.nvim_buf_set_text(0, start_line, start_col, end_line, end_col, l)
            -- TODO move cursor with multiline, need to compute what we added
            vim.api.nvim_win_set_cursor(0, { end_line + 1, end_col })
        else
            vim.api.nvim_put({ new_text }, "c", false, true)
        end
    elseif item.insertText then
        assert(item.insertTextFormat == 1, "only plain text insert is supported, no snippets")
        -- TODO somehow this doesnt seem to do the right thing if you already typed some
        -- its not clear to me if the lsp should give the diff, or if we should understand part of it in the client
        vim.api.nvim_put({ item.insertText }, "c", false, true)
    elseif item.label then
        vim.api.nvim_put({ item.label }, "c", false, true)
    else
        assert(false, "item seems to be missing completion information")
    end
end

--- open the completion items in telescope and select there with fuzzy matching
function M.complete_select()
    -- TODO this is only lazy failsafe
    local client = assert(require("yi.lsp").get_one_lsp_client(), "no lsp client")
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    local replies, error = client:request_sync("textDocument/completion", params, 5000, 0)
    assert(not error, "lst request error")
    -- vim.print { replies = replies, error = error }
    local result = assert((replies or {}).result, "lsp request error")

    local function entry_maker(entry)
        return {
            value = entry,
            display = entry.label .. " [" .. kind_from_id(entry.kind) .. "]",
            ordinal = entry.sortText,
        }
    end

    -- see https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local opts = {}
    pickers
        .new(opts, {
            prompt_title = "completion",
            finder = finders.new_table {
                results = result.items,
                entry_maker = entry_maker,
            },
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
                -- TODO this is so strange, does this replace only apply to this picker? if so, then they must be doing some unholy magic in the back
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    apply_completion(selection.value)
                    vim.schedule(function()
                        -- TODO doesnt quite always end up where it should
                        vim.cmd.startinsert { bang = true }
                    end)
                end)
                map("n", "<esc>", function(prompt_bufnr)
                    actions.close(prompt_bufnr)
                    vim.cmd.startinsert()
                    vim.schedule(function()
                        -- TODO doesnt quite always end up where it should
                        vim.cmd.startinsert { bang = true }
                    end)
                end)
                return true
            end,
        })
        :find()
end

return M
