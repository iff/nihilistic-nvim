local M = {}

-- TODO this argument is to make it so we setup completion before
-- is there a better way to make that happen?
function M.setup(capabilities)
    -- see https://github.com/neovim/nvim-lspconfig
    require("yi.lsps.lua").setup(capabilities)
    require("yi.lsps.python").setup(capabilities)
    require("yi.lsps.rust").setup(capabilities)
    require("yi.lsps.typescript").setup(capabilities)
    require("yi.lsps.yaml").setup(capabilities)
end

function M.go_to_definition()
    M.op("textDocument/definition")(function() end)
end

function M.show_function_signature()
    vim.lsp.buf.signature_help { border = "double", anchor_bias = "above" }
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
        vim.cmd.echom([[no heuristics for this filetype]])
    end
end

function M.goto_docs_browser()
    if vim.bo.filetype == "rust" then
        vim.cmd.RustLsp("openDocs")
    else
        vim.cmd.echom([[no goto web docs for this filetype]])
    end
end

function M.explain_error()
    if vim.bo.filetype == "rust" then
        -- default cycles like diagnostic.goto_next
        -- otherwise use "current"
        vim.cmd.RustLsp("explainError")
    else
        vim.cmd.echom([[no error explanation for this filetype]])
    end
end

-- TODO merge with a,?
function M.open_diagnostic()
    if vim.bo.filetype == "rust" then
        -- should respect lavish layouts
        vim.cmd.RustLsp("renderDiagnostic")
    else
        vim.cmd.echom([[no render diagnostic for this filetype]])
    end
end

function M.open_pkg_manager()
    if vim.bo.filetype == "rust" then
        -- should respect lavish layouts
        vim.cmd.RustLsp("openCargo")
    else
        vim.cmd.echom([[no pkg manager for this filetype]])
    end
end

function M.rename_symbol()
    -- TODO uses vim.ui.input()
    -- would be nice to have one that is in vim mode, like after ctrl-f
    -- or rename takes as argument the new name too, so we could to it custom too
    vim.lsp.buf.rename()
    vim.cmd([[:wa]])
end

local function get_one_lsp_client()
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

local function highlight()
    local back = {
        window = vim.api.nvim_get_current_win(),
        cursorline = vim.wo[0].cursorline,
        highlight = vim.api.nvim_get_hl(0, { name = "CursorLine" }),
    }

    vim.wo.cursorline = true
    vim.api.nvim_set_hl(0, "CursorLine", { bg = "#81a1c1" })
    vim.cmd("redraw!")

    local function reset()
        vim.wo[back.window].cursorline = back.cursorline
        vim.api.nvim_set_hl(
            0,
            "CursorLine",
            back.highlight ---@diagnostic disable-line: param-type-mismatch
        )
    end

    return reset
end

function M.op(method)
    local function fn(make)
        local client = get_one_lsp_client()
        if not client then
            return
        end

        local reset_highlight = highlight()

        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        local replies, error = client:request_sync(method, params, 1000, 0)

        if error or not replies or replies.err then
            vim.print { replies = replies, error = error }
            vim.cmd.echomsg([["lsp error"]])
            reset_highlight()
            return
        end

        if not replies.result or #replies.result == 0 then
            vim.cmd.echomsg([["no candidates"]])
            reset_highlight()
            return
        end

        -- TODO offer selection? does builtin do that?
        if #replies.result > 1 then
            vim.print(replies.result)
            vim.cmd.echomsg([["many candidates"]])
        end

        local selected = replies.result[1]

        reset_highlight()

        make()
        vim.lsp.util.show_document(selected, client.offset_encoding)
        vim.cmd("normal! zt")

        -- TODO could we instead highlight only the target word?
        reset_highlight = highlight()
        vim.defer_fn(reset_highlight, 500)
    end
    return fn
end

function M.try_autoimport()
    -- TODO doesnt work, how to easily have the completion menu in normal mode? for autoimports?
    -- TODO this is probably very specific for python, and not yet robust either
    -- could we programatically go to insert mode, call complete, first element, and select?
    -- we expect to be in normal mode after that, so we have to do it directly
    -- we cannot wait, unless we can give an additional mapping into complete?
    -- cmp.complete() does accept config, and cmp.ContextReason?, but config is the same config
    -- where we can have a lot of control
    -- TODO this works, poc, could we have virtual text for the guess import?
    -- and then we just do ctrl-n in normal mode if we like that
    vim.keymap.set("n", "M", function()
        -- TODO we should go to the end of the word, plus one more character
        -- at least for params, not necessarily for vim
        -- TODO or instead we could use only the additionalTextEdits and ignore the current symbol edit
        -- but still, it looks like the proposals are better when done at the end of the symbol
        -- maybe there is an option fo the complete LSP call that gives a hint? no it doesnt
        local params = vim.lsp.util.make_position_params()
        local function handler(_, result, _, _)
            -- full signature: err, result, ctx, config
            for _, item in ipairs(result.items) do
                if item.detail == "Auto-import" then
                    vim.lsp.buf_request(0, "completionItem/resolve", item, function(_, result, ctx, _)
                        -- full signature: err, result, ctx, config
                        local offset_encoding = vim.lsp.get_client_by_id(ctx.client_id).offset_encoding
                        if result.textEdit ~= nil then
                            vim.lsp.util.apply_text_edits({ result.textEdit }, 0, offset_encoding)
                        end
                        if result.additionalTextEdits ~= nil then
                            vim.lsp.util.apply_text_edits(result.additionalTextEdits, 0, offset_encoding)
                        end
                        if result.documentation ~= nil then
                            -- TODO used to be there always in my tests, but not anymore?
                            print(vim.split(result.documentation.value, "\n")[2])
                        else
                            vim.pretty_print(result)
                        end
                    end)
                    return
                end
            end
            print("Did not find any auto-import candidates.")
        end
        vim.lsp.buf_request(0, "textDocument/completion", params, handler)
    end, { desc = "auto-import" })
end

return M
