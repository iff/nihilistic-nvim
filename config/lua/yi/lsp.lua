local M = {}

function M.setup()
    -- applies to all servers configured below; per-server config still merges on top
    vim.lsp.config("*", { capabilities = require("yi.completion").get_capabilities() })

    -- see https://github.com/neovim/nvim-lspconfig
    require("yi.lsps.clangd").setup()
    -- TODO
    require("yi.lsps.lean").setup()
    require("yi.lsps.lua").setup()
    require("yi.lsps.nix").setup()
    require("yi.lsps.python").setup()
    require("yi.lsps.rust").setup()
    require("yi.lsps.typescript").setup()
    require("yi.lsps.yaml").setup()
    require("yi.lsps.zig").setup()
end

function M.go_to_definition()
    M.op("textDocument/definition")(function() end)
end

function M.show_function_signature()
    vim.lsp.buf.signature_help { border = "rounded", anchor_bias = "above" }
end

function M.pick_references()
    vim.lsp.buf.references()
end

function M.highlight_references()
    vim.lsp.buf.document_highlight()
end

function M.clear_highlight_references()
    vim.lsp.buf.clear_references()
end

function M.code_action()
    vim.lsp.buf.code_action()
end

function M.toggle_inlay_hints()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

local function add_ignore_python()
    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local issues = vim.diagnostic.get(0, { lnum = lnum })
    local codes = {}
    for _, issue in ipairs(issues) do
        if issue["source"] == "Pyright" or issue["source"] == "basedpyright" then
            if issue["code"] ~= nil then
                codes[issue["code"]] = true
            end
        end
    end
    for code, _ in pairs(codes) do
        local text = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, true)
        local has, _ = string.find(text[1], "# pyright: ignore")
        if has == nil then
            text[1] = text[1] .. "  # pyright: ignore[" .. code .. "]"
        else
            text[1] = string.sub(text[1], 1, -2) .. ", " .. code .. "]"
        end
        vim.api.nvim_buf_set_lines(0, lnum, lnum + 1, true, text)
    end
end

local function add_ignore_lua()
    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local issues = vim.diagnostic.get(0, { lnum = lnum })
    local codes = {}
    for _, issue in ipairs(issues) do
        if issue["source"] == "Lua Diagnostics." then
            if issue["code"] ~= nil then
                codes[issue["code"]] = true
            end
        end
    end
    for code, _ in pairs(codes) do
        local text = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, true)
        local has, _ = string.find(text[1], "---@diagnostic disable-line:")
        if has == nil then
            text[1] = text[1] .. "  ---@diagnostic disable-line: " .. code
        else
            text[1] = string.sub(text[1], 1, -2) .. ", " .. code
        end
        vim.api.nvim_buf_set_lines(0, lnum, lnum + 1, true, text)
    end
end

function M.add_ignore()
    -- TODO remove those issues right away instead of waiting for lsp to update?
    -- there was a way to remove or hide
    if vim.bo.filetype == "python" then
        add_ignore_python()
    elseif vim.bo.filetype == "lua" then
        add_ignore_lua()
    else
        vim.cmd.echomsg([["no heuristics for this filetype"]])
    end
end

-- function M.goto_docs_browser()
--     if vim.bo.filetype == "rust" then
--         vim.cmd.RustLsp("openDocs")
--     else
--         vim.cmd.echomsg([["no goto web docs for this filetype"]])
--     end
-- end
--
-- function M.explain_error()
--     if vim.bo.filetype == "rust" then
--         -- default cycles like diagnostic.goto_next
--         -- otherwise use "current"
--         vim.cmd.RustLsp("explainError")
--     else
--         vim.cmd.echomsg([[no error explanation for this filetype]])
--     end
-- end
--
-- -- TODO merge with a,?
-- function M.open_diagnostic()
--     if vim.bo.filetype == "rust" then
--         -- should respect lavish layouts
--         vim.cmd.RustLsp("renderDiagnostic")
--     else
--         vim.cmd.echom([["no render diagnostic for this filetype"]])
--     end
-- end
--
-- function M.open_pkg_manager()
--     if vim.bo.filetype == "rust" then
--         -- should respect lavish layouts
--         vim.cmd.RustLsp("openCargo")
--     else
--         vim.cmd.echomsg([["no pkg manager for this filetype"]])
--     end
-- end

function M.rename_symbol()
    -- TODO uses vim.ui.input()
    -- would be nice to have one that is in vim mode, like after ctrl-f
    -- or rename takes as argument the new name too, so we could to it custom too
    vim.lsp.buf.rename()
    vim.cmd([[:wa]])
end

function M.get_one_lsp_client()
    local clients = vim.lsp.get_clients { bufnr = 0 }
    if #clients == 0 then
        vim.cmd.echomsg([["no lsp on this buffer"]])
        return nil
    elseif #clients == 1 then
        return clients[1]
    else
        vim.cmd.echomsg([["more than one lsp on this buffer"]])
        return clients[1]
    end
end

function M.op(method)
    local function fn(make)
        local client = M.get_one_lsp_client()
        if not client then
            return
        end

        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        local replies, error = client:request_sync(method, params, 2000, 0)

        if error or not replies or replies.err then
            vim.print { replies = replies, error = error }
            vim.cmd.echomsg([["lsp error"]])
            return
        end

        if not replies.result or #replies.result == 0 then
            vim.cmd.echomsg([["no candidates"]])
            return
        end

        if #replies.result > 1 then
            require("snacks.picker").lsp_definitions()
            return
        end

        local selected = replies.result[1]

        make()
        vim.lsp.util.show_document(selected, client.offset_encoding)
        vim.cmd("normal! zt")
    end
    return fn
end

return M
