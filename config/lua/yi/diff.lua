local M = {}

-- for jj diff the buffer against the file contents in the parent change
local function jj_source()
    local function set_ref(buf_id)
        local path = vim.api.nvim_buf_get_name(buf_id)
        if path == "" or vim.fn.filereadable(path) == 0 then
            return
        end
        vim.system(
            { "jj", "file", "show", "-r", "@-", "--", path },
            { text = true, cwd = vim.fn.fnamemodify(path, ":h") },
            vim.schedule_wrap(function(out)
                if not vim.api.nvim_buf_is_valid(buf_id) then
                    return
                end
                -- non-zero: path absent in @-, treat the whole buffer as added
                local ref = out.code == 0 and (out.stdout or "") or ""
                require("mini.diff").set_ref_text(buf_id, ref)
            end)
        )
    end

    return {
        name = "jj",
        attach = function(buf_id)
            if vim.fs.root(buf_id, ".jj") == nil then
                -- fall through to the git source
                return false
            end
            set_ref(buf_id)
            local group = vim.api.nvim_create_augroup("MiniDiffJj_" .. buf_id, { clear = true })
            vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained", "ShellCmdPost" }, {
                group = group,
                buffer = buf_id,
                callback = function()
                    set_ref(buf_id)
                end,
            })
        end,
        detach = function(buf_id)
            pcall(vim.api.nvim_del_augroup_by_name, "MiniDiffJj_" .. buf_id)
        end,
    }
end

local function nav(direction, diff_key)
    return function()
        if vim.wo.diff then
            vim.cmd.normal { diff_key, bang = true }
        else
            require("mini.diff").goto_hunk(direction, { wrap = true })
        end
    end
end

M.next_hunk = nav("next", "]c")
M.prev_hunk = nav("prev", "[c")
M.toggle_inline = function()
    require("mini.diff").toggle_overlay()
end

function M.setup()
    local MiniDiff = require("mini.diff")

    MiniDiff.setup {
        source = { jj_source(), MiniDiff.gen_source.git() },
        view = {
            style = "sign",
            -- default signs too wide for me
            signs = { add = "┃", change = "┃", delete = "┃" },
        },
        mappings = {
            apply = "",
            reset = "",
            textobject = "",
            goto_first = "",
            goto_prev = "",
            goto_next = "",
            goto_last = "",
        },
    }
end

return M
