local M = {}

function M.setup()
    M.setup_luasnip()
    M.setup_cmp()
end

function M.setup_luasnip()
    -- see https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md
    local ls = require("luasnip")
    local s = ls.snippet
    local t = ls.text_node
    ls.add_snippets("all", { s("!class", { t("class") }) })
end

function M.setup_cmp()
    local cmp = require("cmp")
    -- require("cmp").get_entries() gives access while in insert mode to this, if I want to try my own thing
    cmp.setup {
        view = { entries = { name = "wildmenu", separator = " | " }, docs = { auto_open = true } },
        -- experimental={ghost_text=true},
        completion = {
            autocomplete = false,
        },
        snippet = {
            expand = function(args)
                require("luasnip").lsp_expand(args.body)
            end,
        },
        window = {
            completion = vim.tbl_extend("force", cmp.config.window.bordered(), { max_height = 20 }),
            documentation = vim.tbl_extend("force", cmp.config.window.bordered(), { max_height = 20 }),
        },
        preselect = cmp.PreselectMode.None,
        mapping = {
            ["<c-e>"] = cmp.mapping.select_next_item(),
            ["<c-u>"] = cmp.mapping.select_prev_item(),
            -- ["<c-y>"] = cmp.mapping.open_docs(),
            -- ["<c-k>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
            -- ["<c-h>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
            -- TODO comma doesnt seem to work with ctrl
            -- ["<c-,>"] = cmp.mapping.abort(),
            -- TODO it doesnt really abort, when typing more it keeps on autotriggering :/
            ["<c-y>"] = cmp.mapping.abort(),
            ["<enter>"] = cmp.mapping.confirm { select = true },
            ["<c-l>"] = function()
                cmp.abort()
                cmp.complete {
                    config = {
                        view = {
                            entries = { name = "custom", selection_order = "near_cursor" },
                            docs = { auto_open = true },
                        },
                    },
                }
            end,
        },
        experimental = {
            ghost_text = true,
        },
        -- see https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources
        -- TODO removed buffer as source, but still seems to be happening ...
        sources = cmp.config.sources {
            { name = "nvim_lsp" },
            -- TODO should not be here for most filetypes, ah but I think it does it itself
            { name = "nvim_lua" },
            -- TODO start trying, and see how to work with or combine with iabbrev?
            { name = "luasnip" },
            --{name='buffer'},
        },
        formatting = {
            format = require("lspkind").cmp_format {
                mode = "symbol_text",
                maxwidth = 50,
                menu = {
                    buffer = "[buffer]",
                    nvim_lsp = "[lsp]",
                    nvim_lua = "[lua]",
                },
            },
        },
    }

    -- enable completing paths in :
    -- cmp.setup.cmdline(":", {
    --     sources = cmp.config.sources {
    --         { name = "path" },
    --     },
    -- })
end

function M.complete_flat()
    local cmp = require("cmp")
    cmp.complete {
        config = {
            view = { entries = { name = "wildmenu", separator = " | " }, docs = { auto_open = true } },
        },
    }
end
function M.complete_full()
    local cmp = require("cmp")
    cmp.complete {
        config = {
            view = { entries = { name = "custom", selection_order = "near_cursor" }, docs = { auto_open = true } },
        },
    }
end

function M.get_capabilities()
    return require("cmp_nvim_lsp").default_capabilities()
end

return M
