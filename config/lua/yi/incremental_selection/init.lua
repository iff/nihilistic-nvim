-- Extracted from https://github.com/MeanderingProgrammer/treesitter-modules.nvim
-- Apache-2.0 License

local Range = require("yi.incremental_selection.range")

---@class yi.treesitter.Selection
local M = {}

---@private
M.nodes = require("yi.incremental_selection.nodes").new()

---@private
---@param buf integer
---@param language string
---@return vim.treesitter.LanguageTree?
function M.parse(buf, language)
    local has, parser = pcall(vim.treesitter.get_parser, buf, language)
    if not has or not parser then
        return nil
    end
    -- 1-indexed inclusive -> 0-indexed exclusive
    local first, last = vim.fn.line("w0"), vim.fn.line("w$")
    parser:parse { first - 1, last }
    return parser
end

---@private
---@param node TSNode
function M.select(node)
    local range = Range.node(node)
    if vim.api.nvim_get_mode().mode ~= "v" then
        vim.cmd.normal { "v", bang = true }
    end
    vim.api.nvim_win_set_cursor(0, range:cursor_start())
    vim.cmd.normal { "o", bang = true }
    vim.api.nvim_win_set_cursor(0, range:cursor_end())
end

---@private
---@param language string
---@param name 'highlights'|'indents'|'locals'
---@return boolean
local function has_query(language, name)
    return #vim.treesitter.query.get_files(language, name) > 0
end

---@private
---@param buf integer
---@param language string
---@param root TSNode
---@return TSNode[]
function M.scopes(buf, language, root)
    if not has_query(language, "locals") then
        return {}
    end
    local query = vim.treesitter.query.get(language, "locals")
    if not query then
        return {}
    end
    local result = {} ---@type TSNode[]
    local start, _, stop, _ = root:range()
    for _, match in query:iter_matches(root, buf, start, stop + 1) do
        for id, nodes in pairs(match) do
            local capture = query.captures[id]
            if capture == "local.scope" then
                for _, node in ipairs(nodes) do
                    result[#result + 1] = node
                end
            end
        end
    end
    return result
end

---@private
---@param buf integer
---@param language string
---@param parent fun(parser: vim.treesitter.LanguageTree, node: TSNode): TSNode?
function M.incremental(buf, language, parent)
    local parser = M.parse(buf, language)
    if not parser then
        return
    end

    local range = Range.visual()
    local last = M.nodes:last(buf)
    local node = nil ---@type TSNode?

    if not last or not range:same(Range.node(last)) then
        -- handle re-initialization
        node = parser:named_node_for_range(range:ts(), {
            ignore_injections = false,
        })
        M.nodes:clear(buf)
    else
        -- iterate through parent parsers and nodes until we find a node with
        -- a different range
        parser = parser:language_for_range(range:ts())
        while parser and not node do
            node = parser:named_node_for_range(range:ts())
            while node and range:same(Range.node(node)) do
                node = parent(parser, node)
            end
            parser = parser:parent()
        end
    end

    if node then
        M.nodes:push(buf, node)
        M.select(node)
    end
end

-- Public API functions

function M.init_selection()
    local buf = vim.api.nvim_get_current_buf()
    local parser = M.parse(buf, vim.bo[buf].filetype)
    if not parser then
        return
    end
    local node = vim.treesitter.get_node {
        bufnr = buf,
        ignore_injections = false,
    }
    if node then
        M.nodes:push(buf, node)
        M.select(node)
    end
end

function M.node_incremental()
    local buf = vim.api.nvim_get_current_buf()
    M.incremental(buf, vim.bo[buf].filetype, function(parser, node)
        return node:parent()
    end)
end

function M.scope_incremental()
    local buf = vim.api.nvim_get_current_buf()
    M.incremental(buf, vim.bo[buf].filetype, function(parser, node)
        local language = vim.bo[buf].filetype
        if language ~= parser:lang() then
            -- only handle scope for root language
            return nil
        end
        local scopes = M.scopes(buf, language, parser:trees()[1]:root())
        if #scopes == 0 then
            return nil
        end
        local result = node:parent()
        while result and not vim.tbl_contains(scopes, result) do
            result = result:parent()
        end
        assert(result ~= node, "infinite loop")
        return result
    end)
end

function M.node_decremental()
    local buf = vim.api.nvim_get_current_buf()
    local node = M.nodes:pop(buf)
    if node then
        M.select(node)
    end
end

return M
