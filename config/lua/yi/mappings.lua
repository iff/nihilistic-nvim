local M = {}

-- moody mappings
-- how to make it modal?
-- what is a good spec for it, and what about shadowing, and prefix overlaps?
-- and should modes be per window, or global?
-- global would mean we only need to do things on keystrokes
-- otherwise we need to add events
-- but no matter what, the original modes will always interfere potentially
-- we already almost have "modes" in most ways, it's generally about repeating (?)
-- or you define sets of mappings (like layers), and you say when you want which, and they can be layered on top
-- but for simple cases, you dont want layered, just one
-- lets call it mode and mood, moods are on top of modes, modes and moods are orthogonal
-- so we use clear and reapply fresh? :mapclear, but could it be a problem for plugins that i dont control?
-- we could also try quick and dirty just overlay and hope for the best
-- names: macho, mad, manic, moody, motivated/ing, mutual, middle, militant, mighty, moving
-- relevant: https://github.com/debugloop/layers.nvim/tree/main

---@type "default" | "search" | "diagnostic"
M.mode = "default"

local n, i, v, o, nv, ni, c = "n", "i", "v", "o", "nv", "ni", "c"

-- consider https://colemakmods.github.io/mod-dh/model.html when it comes to reachability

---@class (exact) Map
---@field [1] string lhs
---@field [2] string modes (can be many)
---@field [3] string desc
---@field rhs? string rhs, or it is a group with no functionality if nothing is mapped
---@field expr? fun() expression
---@field fn? fun() function
---@field maps? ModeFn new mappings

---@alias ModeFn fun(): string,Map[]

---@class (exact) FlatMap
---@field lhs string lhs
---@field mode "n" | "i" | "v" | "o" | "c" mode (just one)
---@field desc string desc
---@field rhs? string rhs
---@field expr? fun() expression
---@field fn? fun() function
---@field maps? ModeFn new mappings

---@param maps Map[]
---@return FlatMap[]
local function flatten_maps(maps)
    local flat = {}
    for _, m in ipairs(maps) do
        for mode in string.gmatch(m[2], ".") do
            -- TODO would it make sense to validate here?
            table.insert(flat, {
                lhs = m[1],
                mode = mode,
                desc = m[3],
                rhs = m.rhs,
                expr = m.expr,
                fn = m.fn,
                maps = m.maps,
            })
        end
    end
    return flat
end

---@param maps? Map[] mappings (defaults to M.get())
function M.apply(maps)
    maps = maps or M.get()
    M.validate(maps)
    M.clear()
    M.apply_plain(maps)
    -- M.apply_which_key(maps)
    -- M.apply_legendary(maps)
end

---@generic A
---@param array A[] array
---@param fn fun(element: A) fn
local function foreach(array, fn)
    for _, element in ipairs(array) do
        fn(element)
    end
end

-- TODO add something that gives you free prefixes if you are looking where to place new mappings?
---@param maps Map[]
function M.validate(maps)
    local flat = flatten_maps(maps)
    for a, am in ipairs(flat) do
        if am.rhs or am.expr or am.fn or am.maps then
            local ak = vim.keycode(am.lhs)
            for b, bm in ipairs(flat) do
                if a ~= b and (am.mode == bm.mode) and (bm.rhs or bm.expr or bm.fn or bm.maps) then
                    local bk = vim.keycode(bm.lhs)
                    if ak == string.sub(bk, 1, string.len(ak)) then
                        vim.print(
                            am.lhs
                                .. " is a prefix of "
                                .. bm.lhs
                                .. " from "
                                .. am.mode
                                .. "'"
                                .. am.desc
                                .. "' and "
                                .. bm.mode
                                .. "'"
                                .. bm.desc
                                .. "'"
                        )
                    end
                end
            end
        end
    end
end

---@return Map[] mappings
function M.get()
    ---@type Map[]
    local maps = {}
    vim.list_extend(maps, M.fixes())
    vim.list_extend(maps, M.cmd_mode())
    --
    vim.list_extend(maps, M.for_moves())
    vim.list_extend(maps, M.for_inserts())
    vim.list_extend(maps, M.for_edit())
    vim.list_extend(maps, M.for_changes())
    vim.list_extend(maps, M.for_indentation())
    vim.list_extend(maps, M.for_operators())
    vim.list_extend(maps, M.for_visual())
    vim.list_extend(maps, M.for_copy_paste())
    vim.list_extend(maps, M.for_search())
    vim.list_extend(maps, M.for_windows())
    vim.list_extend(maps, M.for_jumps())
    vim.list_extend(maps, M.for_comma())
    vim.list_extend(maps, M.for_undos())
    vim.list_extend(maps, M.for_completion())
    vim.list_extend(maps, M.for_comments())
    return maps
end

local function visualize_submode()
    local back = {
        window = vim.api.nvim_get_current_win(),
        -- TODO modes might change window, so that's not so easy
        -- use something else a bit more global for the indication?
        -- plus how did it even work when we switched windows?
        -- cursorline = vim.wo[0].cursorline,
        -- highlight = vim.api.nvim_get_hl(0, { name = "CursorLine" }),
        -- signcolumn = vim.api.nvim_get_hl(0, { name = "SignColumn" }),
        normal = vim.api.nvim_get_hl(0, { name = "Normal" }),
    }

    -- https://github.com/morhetz/gruvbox/tree/master?tab=readme-ov-file
    local colors = {
        blue = "#458588",
        green = "#98971a",
        aqua = "#689d6a",
        yiblue = "#81a1c1",
    }

    -- vim.wo.cursorline = true
    -- TODO underline or so could also be nice instead
    -- vim.api.nvim_set_hl(0, "CursorLine", { bg = colors.green })
    -- vim.api.nvim_set_hl(0, "SignColumn", { bg = colors.green })
    vim.api.nvim_set_hl(0, "Normal", { bg = colors.mix })
    vim.cmd.redraw()

    local function reset()
        -- vim.wo[back.window].cursorline = back.cursorline
        -- vim.api.nvim_set_hl(
        --     0,
        --     "CursorLine",
        --     back.highlight ---@diagnostic disable-line: param-type-mismatch
        -- )
        -- vim.api.nvim_set_hl(
        --     0,
        --     "SignColumn",
        --     back.signcolumn ---@diagnostic disable-line: param-type-mismatch
        -- )
        vim.api.nvim_set_hl(
            0,
            "Normal",
            back.normal ---@diagnostic disable-line: param-type-mismatch
        )
    end

    return reset
end

local reset_visualized_submode = nil

---@param mode ModeFn
local function switch_submode(mode)
    local name, maps = mode()
    M.mode = name
    if name == "default" then
        if reset_visualized_submode then
            reset_visualized_submode()
        end
        reset_visualized_submode = nil
    else
        reset_visualized_submode = visualize_submode()
    end
    -- NOTE this also clears all mappings, very aggressive
    M.apply(maps)
    vim.cmd.redrawstatus()
    vim.cmd.redrawtabline()
end

---@param mode ModeFn
---@param rhs string
local function fn_submode_rhs(mode, rhs)
    return function()
        switch_submode(mode)
        return rhs
    end
end

---@param mode ModeFn
---@param expr fun()
local function fn_submode_expr(mode, expr)
    return function()
        switch_submode(mode)
        return expr()
    end
end

---@param mode ModeFn
---@param fn fun()
local function fn_submode_fn(mode, fn)
    return function()
        switch_submode(mode)
        fn()
    end
end

--- apply using nvim api
---@param maps Map[] mappings to apply
function M.apply_plain(maps)
    local flat = flatten_maps(maps)
    foreach(flat, function(map)
        if map.maps then
            if map.rhs then
                vim.keymap.set(map.mode, map.lhs, fn_submode_rhs(map.maps, map.rhs), { desc = map.desc, expr = true })
            elseif map.expr then
                vim.keymap.set(map.mode, map.lhs, fn_submode_expr(map.maps, map.expr), { desc = map.desc, expr = true })
            elseif map.fn then
                vim.keymap.set(map.mode, map.lhs, fn_submode_fn(map.maps, map.fn), { desc = map.desc })
            else
                vim.keymap.set(map.mode, map.lhs, fn_submode_fn(map.maps, function() end), { desc = map.desc })
            end
        else
            if map.rhs then
                vim.keymap.set(map.mode, map.lhs, map.rhs, { desc = map.desc })
            elseif map.expr then
                vim.keymap.set(map.mode, map.lhs, map.expr, { desc = map.desc, expr = true })
            elseif map.fn then
                vim.keymap.set(map.mode, map.lhs, map.fn, { desc = map.desc })
            end
        end
    end)
end

--- clear mappings
function M.clear()
    -- see :help default_mappings and other places
    -- currently just removing what i bumped into
    -- there was a way to clear all, including built-in I think

    -- NOTE difference between deleting a mapping and unsetting a default

    -- local del = vim.keymap.del
    -- del(n, "<c-w>d")
    -- del(n, "<c-w><c-d>")
    -- TODO damn ... because this happens after us? comes from matchit, a pack, but it's before the config path
    -- but we run init directly, so that happens before somehow?
    -- its a mess, plugins happen after my init ... so how can i undo things from them?
    -- how can i make my init run at the very end then?
    -- del(o, "[%") -- NOTE comes from "matchit"
    vim.cmd([[let loaded_matchit = 1]]) -- TODO as a hack now, still dont know how to not get overwritten by plugins

    -- TODO try generically to delete all
    -- and there is also nvim_buf_get_keymap ... how to make sure we always have a clean slate?
    vim.iter(vim.api.nvim_get_keymap("n")):each(function(map)
        vim.api.nvim_del_keymap("n", map.lhs)
        -- del(map.mode, map.lhs)
    end)

    -- TODO help index.txt has a list, but need to parse it, there is no api to get all of those
    local letters = [[abcdefghijklmnopqrstuvwxyz]]
    for at = 1, #letters do
        local char = string.sub(letters, at, at)
        vim.keymap.set(n, "<c-" .. char .. ">", "<nop>")
        vim.keymap.set(v, "<c-" .. char .. ">", "<nop>")
        vim.keymap.set(o, "<c-" .. char .. ">", "<nop>")
    end
    local keys = [[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ&*()\%@;+![]|~":-={}$#_<>?']]
    for at = 1, #keys do
        local char = string.sub(keys, at, at)
        vim.keymap.set(n, char, "<nop>")
        vim.keymap.set(v, char, "<nop>")
        vim.keymap.set(o, char, "<nop>")
    end
end

--- apply to which key (not setting any maps)
---@param maps Map[] mappings to apply
function M.apply_which_key(maps)
    local groups = {}
    for _, map in ipairs(maps) do
        for _, mode in ipairs(vim.iter(string.gmatch(map.mode, ".")):totable()) do
            if map.rhs or map.expr or map.fn then
            else
                -- TODO i still dont seem to see anything after typing 'w'
                table.insert(groups, { map.lhs, mode = mode, group = map.desc })
            end
        end
    end
    -- see https://github.com/folke/which-key.nvim
    require("which-key").setup {
        spec = groups,
        plugins = {
            marks = false,
            registers = false,
            spelling = false,
            presets = {
                operators = false,
                motions = false,
                text_objects = false,
                windows = false,
                nav = false,
                z = false,
                g = false,
            },
        },
    }
    -- TODO ':checkhealth which-key' will show if you have duplicates and/or overlaps; does it work when not set here?
end

--- apply to legendary (not setting any maps)
---@param maps Map[] mappings to apply
function M.apply_legendary(maps)
    local spec = {}
    for _, map in ipairs(maps) do
        for _, mode in ipairs(vim.iter(string.gmatch(map.mode, ".")):totable()) do
            if map.rhs or map.expr or map.fn then
                table.insert(spec, { map.lhs, mode = mode, desc = map.desc })
            end
        end
    end
    -- TODO didnt show me n, showed me a bunch of built-ins, including the old n
    -- require("legendary").setup({ extensions = { which_key = { auto_register = true, do_binding = false } } })
    -- see https://github.com/mrjones2014/legendary.nvim
    require("legendary").setup {
        include_builtin = false,
        keymaps = spec,
    }
end

---@param map Map map
---@return Map
local function validated_map(map)
    -- the lua lsp is not so robust yet, we cant have it make sure we didnt pass invalid stuff
    -- so we validate here for sanity
    if map[1] == nil or map[2] == nil or map[3] == nil then
        vim.print("broken map args, missing args", map)
    end
    if (map.rhs and 1 or 0) + (map.expr and 1 or 0) + (map.fn and 1 or 0) > 1 then
        vim.print("broken map args, more than one action", map)
    end
    local allowed = { [1] = true, [2] = true, [3] = true, rhs = true, expr = true, fn = true, maps = true }
    if
        not vim.iter(pairs(map)):all(function(key, _)
            if allowed[key] then
                return true
            end
            vim.print { key = key, allowed = allowed[key] }
            return allowed[key]
        end)
    then
        vim.print("broken map args, unknown args", map)
    end

    return map
end

---@param maps Map[] maps
---@return Map[]
local function validated_maps(maps)
    for _, map in ipairs(maps) do
        validated_map(map)
    end
    return maps
end

---@param delay number milliseconds
---@param disengage number milliseconds
local function rapid_trigger_context(delay, disengage)
    local last = vim.uv.now() - delay ---@diagnostic disable-line: undefined-field
    local engaged = false

    ---@param slow fun(): string
    ---@param fast fun(): string
    ---@return fun(): string
    return function(slow, fast)
        return function()
            local now = vim.uv.now() ---@diagnostic disable-line: undefined-field
            local elapsed = now - last
            last = now
            if not engaged and elapsed < delay then
                engaged = true
                return fast()
            end
            if engaged and elapsed < disengage then
                return fast()
            end
            engaged = false
            return slow()
        end
    end
end

--------------------------------------------

function M.fixes()
    local function cr()
        local expr = function()
            if vim.o.buftype == "quickfix" then
                return ":.cc<CR>"
            else
                -- TODO maybe bind something interesting here?
                return "<CR>"
            end
        end
        return expr
    end
    -- FIXME might need? { replace_keycodes = true }

    return validated_maps {
        { [[<CR>]], n, "fix cr for quickfix", expr = cr() },
    }
end

function M.cmd_mode()
    -- TODO where and how?
    vim.api.nvim_create_autocmd("CmdwinEnter", {
        callback = function()
            vim.keymap.set({ "n", "v" }, "<esc>", "<c-w>c", { buffer = true })
        end,
    })

    local function super_command(mode)
        local expr = function()
            local old = vim.opt.splitkeep
            vim.opt.splitkeep = "topline"
            vim.api.nvim_create_autocmd("CmdwinLeave", {
                callback = function()
                    vim.opt.splitkeep = old -- NOTE to prevent the main view from jumping
                    return true
                end,
                once = true,
            })
            return "q:" .. mode
        end
        return expr
    end

    return validated_maps {
        { ":", n, "command mode in insert mode", expr = super_command("i") },
        { ":", v, "command mode in insert mode", expr = super_command("i") },
        { ";", n, "command mode in normal mode", expr = super_command("k") },
        { ";", v, "command mode in normal mode", expr = super_command("k") },
    }
end

-------------

function M.for_moves()
    --- switch to character visual when in line visual
    local function vv(rhs)
        return function()
            if vim.list_contains({ "V", "Vs" }, vim.api.nvim_get_mode().mode) then
                return "v" .. rhs
            else
                return rhs
            end
        end
    end

    local rapid = rapid_trigger_context(50, 1000)

    local function slow_down()
        return "j"
    end
    local function fast_down()
        if vim.fn.winline() < vim.fn.winheight(0) / 2 then
            -- return "j"
            return "gj" -- treats wrapped lines as they appear
        else
            -- return "1<c-d>"
            -- NOTE the above moves the cursor horizontally, the below works, but flickers a bit
            return "gj<c-e>"
        end
    end
    local some_down = rapid(slow_down, fast_down)

    local function slow_up()
        -- return "k"
        return "gk" -- treats wrapped lines as they appear
    end
    local function fast_up()
        if vim.fn.winline() > vim.fn.winheight(0) / 2 then
            return "gk" -- treats wrapped lines as they appear
        else
            -- return "1<c-u>"
            -- NOTE the above moves the cursor horizontally, the below works, but flickers a bit
            return "gk<c-y>"
        end
    end
    local some_up = rapid(slow_up, fast_up)

    return validated_maps {
        -- plain
        { [[n]], nv, "cursor left", expr = vv("h") },
        -- { [[e]], nv, "cursor down", rhs = "j" },
        { [[e]], nv, "cursor down", expr = some_down },
        { [[i]], nv, "cursor right", expr = vv("l") },
        -- { [[u]], nv, "cursor up", rhs = "k" },
        { [[u]], nv, "cursor up", expr = some_up },
        { [[<up>]], nv, "view and cursor up", rhs = "1<c-u>" },
        { [[<down>]], nv, "view and cursor down", rhs = "1<c-d>" },

        -- words
        { [[l]], nv, "previous word start", expr = vv("b") },
        { [[ l]], nv, "previous word end", expr = vv("ge") },
        { [[<c-l>]], nv, "previous WORD start", expr = vv("B") },

        { [[y]], nv, "next word start", expr = vv("w") },
        { [[ y]], nv, "next word end", expr = vv("e") },
        { [[<c-y>]], nv, "next WORD end", expr = vv("W") },

        -- bigger
        { [[ n]], nv, "view and cursor to start of text in line", expr = vv("0^") }, -- [[m]]
        { [[aan]], nv, "cursor to start of line", expr = vv("0") }, -- [[am]]
        { [[ i]], nv, "cursor to end of line", expr = vv("$") }, -- [[o]]
        -- { [[zz]], nv, "center cursor vertically", rhs = "zz" },
        -- TODO this seems to not keep the cursor in the same column? virtual edit is on? yes it is
        -- and it acts very strange, cursor appears in wrong column, but then when you neiu, it jumps to the right place
        { [[k]], nv, "view and cursor one page up", rhs = "<cmd>set scroll=0<enter><c-u><c-u>" },
        { [[ k]], nv, "view and cursor half page up", rhs = "<cmd>set scroll=0<enter><c-u>" },
        { [[h]], nv, "view and cursor one page down", rhs = "<cmd>set scroll=0<enter><c-d><c-d>" },
        { [[ h]], nv, "view and cursor half page down", rhs = "<cmd>set scroll=0<enter><c-d>" },
        { [[ u]], nv, "start of document", rhs = "gg" },
        { [[ e]], nv, "end of document", rhs = "G" },

        -- contextual
        { [[ ,]], nv, "go to last insert and center", rhs = "`^zz" },
        { [[<]], nv, "go to previous jump location", rhs = "<c-o>" },
        { [[<backspace>]], nv, "jump back (tag stack)", rhs = "<ctrl-t>" },
    }
end

function M.for_inserts()
    return validated_maps {
        { [[s]], n, "inserts" },
        { [[sn]], n, "insert before block cursor", rhs = "i" },
        { [[si]], n, "insert after block cursor", rhs = "a" },
        { [[sl]], n, "insert at beginning of word", rhs = "lbi" },
        { [[ssl]], n, "insert at beginning of WORD", rhs = "lBi" },
        { [[sy]], n, "insert at end of word", rhs = "hea" },
        { [[ssy]], n, "insert at end of WORD", rhs = "hEa" },
        { [[so]], n, "insert at end of line", rhs = "A" },
        { [[sm]], n, "insert at beginning of line text", rhs = "^i" },
        -- map { [[ssm]], n, "insert at beginning of line", rhs = "0i" },
        { [[su]], n, "insert new line above", rhs = "O" },
        { [[ssu]], n, "insert new line at top", rhs = "ggO" },
        { [[se]], n, "insert new line below", rhs = "o" },
        { [[sse]], n, "insert new line at bottom", rhs = "Go" },
        { [[s,]], n, "insert at last insert", rhs = "gi" },
        -- TODO map([[s ]], "n", "insert left of hop", todo)
        { [[s e]], n, "insert empty line below", rhs = "o<esc>k" },
        { [[s u]], n, "insert empty line below", rhs = "O<esc>j" },
        { [[s]], v, "insert over visual", rhs = "c" },
    }
end

function M.for_edit()
    return validated_maps {
        -- TODO almost not worth it? and also collides with other stuff
        -- map { [[<c-u>]], i, "new line above", rhs = "<esc>O" },
        -- map { [[<c-e>]], i, "new line below", rhs = "<esc>o" },
        -- { [[<c-enter>]], i, "split into new empty line", rhs = "<enter><enter><esc>O" },
        { [[<c-o>]], i, "split into new empty line", rhs = "<enter><esc>O" },
    }
end

function M.for_changes()
    return validated_maps {
        { [[r]], nv, "change", rhs = "c" },
        { [[ r]], n, "replace single character", rhs = "r" },
        { [[J]], nv, "join lines", rhs = "J" },
        { [[d]], nv, "delete", rhs = "d" },
        { [[<delete>]], n, "delete under cursor", rhs = "x" },
        { [[.]], n, "repeat", rhs = "." },
    }
end

---@type ModeFn
function M.mode_shifts()
    local maps = validated_maps {
        { [[z]], n, "exit", maps = M.mode_default },
        { [[<esc>]], n, "exit", maps = M.mode_default },
        { [[z]], v, "exit", rhs = "<esc>", maps = M.mode_default },
        { [[<esc>]], v, "exit", rhs = "<esc>", maps = M.mode_default },
        { [[u]], nv, "exit and up", rhs = "k", maps = M.mode_default },
        { [[e]], nv, "exit and down", rhs = "j", maps = M.mode_default },
        { [[n]], n, "de-indent current line", rhs = "<<" },
        { [[i]], n, "indent current line", rhs = ">>" },
        -- map { [[pzn]], n, "de-indent last paste", rhs = "'[V']<" },
        -- map { [[pzi]], n, "indent last paste", rhs = "'[V']>" },
        { [[n]], v, "de-indent visual", rhs = "<gv" },
        { [[i]], v, "indent visual", rhs = ">gv" },
    }
    return "shifts", maps
end

function M.for_indentation()
    return validated_maps {
        -- TODO shift makes more sense? and shift up down too?
        -- TODO does repeat maken sense here anyway? if we repeat with . after?
        -- map([[<c-n>]], "n", "de-indent current line", "<<")
        -- map([[<c-i>]], "n", "indent current line", ">>")
        -- map([[p<c-n>]], "n", "de-indent last paste", "'[V']<")
        -- map([[p<c-i>]], "n", "indent last paste", "'[V']>")
        -- map([[<c-n>]], "v", "de-indent visual", "<")
        -- map([[<c-i>]], "v", "indent visual", ">")
        -- { [[zn]], n, "de-indent current line", rhs = "<<" },
        -- { [[zi]], n, "indent current line", rhs = ">>" },
        -- { [[pzn]], n, "de-indent last paste", rhs = "'[V']<" },
        -- { [[pzi]], n, "indent last paste", rhs = "'[V']>" },
        -- { [[zn]], v, "de-indent visual", rhs = "<" },
        -- { [[zi]], v, "indent visual", rhs = ">" },
        { [[z]], nv, "shifts", maps = M.mode_shifts },
    }
end

function M.for_operators()
    return validated_maps {
        -- just like "moves"
        { [[l]], o, "to start of word", rhs = "b" },
        { [[ l]], o, "to start of WORD", rhs = "B" },
        { [[y]], o, "to end of word", rhs = "e" },
        { [[ y]], o, "to end of WORD", rhs = "E" },
        { [[n]], o, "line", rhs = "Vl" },
        { [[ n]], o, "to start of line", rhs = "^" },
        { [[ i]], o, "to end of line", rhs = "$" },
        { [[e]], o, "inner word", rhs = "iw" },
        { [[ e]], o, "inner word with space", rhs = "aw" },
        { [[u]], o, "inner WORD", rhs = "iW" },
        { [[ u]], o, "inner WORD with space", rhs = "aW" },

        -- other
        { [[.]], o, "character", rhs = "l" },
        { [[(]], o, "inner ()", rhs = "i(" },
        { [[)]], o, "outer ()", rhs = "a(" },
        { [[[]], o, "inner []", rhs = "i[" },
        { "]", o, "outer []", rhs = "a[" },
        { [[{]], o, "inner {}", rhs = "i{" },
        { [[}]], o, "outer {}", rhs = "a{" },
        { [["]], o, 'inner ""', rhs = 'i"' },
        { [[ "]], o, 'outer ""', rhs = 'a"' },
        { [[']], o, "inner ''", rhs = "i'" },
        { [[ ']], o, "outer ''", rhs = "a'" },
        { [[<]], o, "inner <>", rhs = "i<" },
        { [[>]], o, "outer <>", rhs = "a<" },

        -- complicated
        -- TODO if there is no comment here, fallback to a line? could be convenient
        { [[c]], o, "a comment", fn = require("vim._comment").textobject },
        { [[p]], o, "inner paragraph", rhs = "ip" },
        { [[ie]], o, "inner paragraph", rhs = "ip" },
        { [[iu]], o, "outer paragraph", rhs = "ap" },
    }
end

function M.for_visual()
    return validated_maps {
        { [[v]], n, "visual lines", rhs = "V" },
        -- map([[v]], "v", "visual characters", "v") -- instead use column moves to switch to characters
        { [[av]], n, "visual block", rhs = "<c-v>" },
        -- TODO collides with d for delete
        -- map { [[dv]], n, "previous visual", rhs = "gv" },
        { [[v]], v, "exit visual", rhs = "<esc>" },
        { [[av]], v, "other side", rhs = "o" },
    }
end

---@param rhs string mapping
---@param mode "" | "c" | "l" mode to paste in (irrespective of yanked mode)
---@return fun()
local function fn_pasted(rhs, mode)
    return function()
        local restore = vim.fn.getreginfo("z")
        if mode ~= "" then
            vim.fn.setreg("z", vim.fn.getreg("z"), mode)
        end
        -- TODO not sure about the escaping here, would nvim_feedkeys be better? also looks complicated there
        vim.cmd.normal { rhs, bang = true }
        if mode ~= "" then
            vim.fn.setreg("z", restore.regcontents, restore.regtype)
        end
        local ns = vim.api.nvim_create_namespace("pasted")
        -- TODO check if that works also for character-based stuff
        -- because in normal vim ' is for line-based marks and ` is for character-based marks
        vim.hl.range(0, ns, "IncSearch", "'[", "']", { timeout = 100 })
    end
end

function M.for_copy_paste()
    -- copy paste
    -- NOTE we use register "z" so that other change operations dont interfere
    -- NOTE we use mark "z" to control cursor location after pastes
    -- TODO the original y and p are not mapped, and we cant use registers on purpose then
    -- TODO is it better more analytic? paste is just paste, and a thing that moves to end or start?
    -- NOTE both x and c keep cursor where it was
    -- TODO is there a way to paste and use the indentation from the cursor (not the text)
    return validated_maps {
        { [[c]], n, "copy", rhs = [["zy]] },
        { [[c]], v, "copy", rhs = [[mz"zy`z]] },
        { [[x]], n, "cut", rhs = [["zd]] },
        { [[x]], v, "cut", rhs = [[mz"zd`z]] },

        -- NOTE "yY copies into y, '< moves to start/end, "yp pastes
        { [[adu]], v, "duplicate above", rhs = [["yY'<"yP]] },
        { [[ade]], v, "duplicate below", rhs = [["yY'>"yp]] },
        {
            [[acu]],
            v,
            "comment and duplicate above",
            rhs = [[mz"yY'<"yP'[V']<cmd>lua require'vim._comment'.operator('line')<enter>V`z]],
        },
        {
            [[ace]],
            v,
            "comment and duplicate below",
            rhs = [[mz"yY'>"yp'[V']<cmd>lua require'vim._comment'.operator('line')<enter>V`z]],
        },

        { [[p]], n, "paste, adapt indentation, and stay" },
        { [[pu]], n, "insert above", fn = fn_pasted([[mz"z]P`z]], "l") },
        { [[pe]], n, "insert below", fn = fn_pasted([[mz"z]p`z]], "l") },
        { [[pn]], n, "insert before", fn = fn_pasted('"zP`]l', "c") },
        { [[pi]], n, "insert after", fn = fn_pasted('"zp`[h', "c") },
        { [[pm]], n, "insert at beginning of text in line", fn = fn_pasted([[mz0^"zP`z]], "c") },
        { [[pan]], n, "insert at beginning of text in line", fn = fn_pasted([[mz0^"zP`z]], "c") },
        { [[po]], n, "insert at end of line", fn = fn_pasted([[mz$"zp`z]], "c") },
        { [[pai]], n, "insert at end of line", fn = fn_pasted([[mz$"zp`z]], "c") },

        { [[p ]], n, "but keep indentation" },
        { [[p u]], n, "insert above", fn = fn_pasted([[mz"zP`z]], "l") },
        { [[p e]], n, "insert below", fn = fn_pasted([[mz"zp`z]], "l") },
        { [[p n]], n, "insert before", fn = fn_pasted('"zP`]k', "c") },
        { [[p i]], n, "insert after", fn = fn_pasted('"zp`[h', "c") },

        -- TODO do we want the but move versions? totally forgot. we move to where?
        { [[pp]], n, "but move" },
        { [[ppu]], n, "insert above", fn = fn_pasted('"z]P`[', "l") },
        { [[ppe]], n, "insert below", fn = fn_pasted('"z]p`]', "l") },
        { [[ppn]], n, "insert before", fn = fn_pasted('"zP`[', "c") },
        { [[ppi]], n, "insert after", fn = fn_pasted('"zp`]', "c") },
        { [[ppm]], n, "insert at beginning of text in line", fn = fn_pasted('0^"zP`[', "c") },
        { [[ppan]], n, "insert at beginning of text in line", fn = fn_pasted('0^"zP`[', "c") },
        { [[ppo]], n, "insert at end of line", fn = fn_pasted('$"zp`z`]', "c") },
        { [[ppai]], n, "insert at end of line", fn = fn_pasted('$"zp`z`]', "c") },

        { [[pp ]], n, "but keep indentation" },
        { [[pp u]], n, "insert above", fn = fn_pasted('"zP`[', "l") },
        { [[pp e]], n, "insert below", fn = fn_pasted('"zp`]', "l") },
        { [[pp m]], n, "insert before", fn = fn_pasted('"zP`[', "c") },
        { [[pp n]], n, "insert before", fn = fn_pasted('"zP`[', "c") },
        { [[pp o]], n, "insert after", fn = fn_pasted('"zp`]', "c") },
        { [[pp i]], n, "insert after", fn = fn_pasted('"zp`]', "c") },

        { [[p]], v, "replace visual with paste", fn = fn_pasted([["zp]], "") },
    }
end

---@type ModeFn
function M.mode_default()
    return "default", M.get()
end

---@param maps Map[]
---@param fallbacks Map[]
---@return Map[]
local function maps_with_fallback(maps, fallbacks)
    local flat = flatten_maps(maps)
    local flat_fallbacks = flatten_maps(fallbacks)

    local merged = {}

    for _, map in ipairs(flat) do
        table.insert(
            merged,
            { map.lhs, map.mode, map.desc, rhs = map.rhs, expr = map.expr, fn = map.fn, maps = map.maps }
        )
    end

    local function has_conflict(fmap)
        for _, map in ipairs(flat) do
            if map.rhs or map.expr or map.fn or map.maps then
                if
                    (fmap.lhs == string.sub(map.lhs, 1, string.len(fmap.lhs)))
                    or (map.lhs == string.sub(fmap.lhs, 1, string.len(map.lhs)))
                then
                    return true
                end
            end
        end
        return false
    end

    for _, map in ipairs(flat_fallbacks) do
        if not has_conflict(map) then
            if map.rhs or map.expr or map.fn then
                table.insert(merged, {
                    map.lhs,
                    map.mode,
                    map.desc,
                    rhs = map.rhs,
                    expr = map.expr,
                    fn = map.fn,
                    -- TODO some modes want to do other things when disabling, like search needs :nohl
                    maps = map.maps or M.mode_default,
                })
            else
                table.insert(merged, {
                    map.lhs,
                    map.mode,
                    map.desc,
                    rhs = map.rhs,
                    expr = map.expr,
                    fn = map.fn,
                    maps = map.maps,
                })
            end
        end
    end

    return validated_maps(merged)
end

---@type ModeFn
function M.mode_search()
    local maps = validated_maps {
        { [[u]], n, "previous match", rhs = "Nzz" },
        { [[e]], n, "next match", rhs = "nzz" },
        { [[<esc>]], n, "end search", rhs = "<cmd>nohlsearch<enter>", maps = M.mode_default },
        { [[f]], n, "end search", rhs = "<cmd>nohlsearch<enter>", maps = M.mode_default },
        { [[<enter>]], n, "end search", rhs = "<cmd>nohlsearch<enter>", maps = M.mode_default },
    }
    return "search", maps_with_fallback(maps, M.get())
end

function M.for_search()
    return validated_maps {
        { [[f]], n, "search" },
        { [[ff]], n, "from the beginning", rhs = "gg0/", maps = M.mode_search },
        { [[fu]], n, "backwards", rhs = "?", maps = M.mode_search },
        { [[fe]], n, "forward", rhs = "/", maps = M.mode_search },
        { [[fn]], n, "word backwards", rhs = "#", maps = M.mode_search },
        { [[fi]], n, "word forward", rhs = "*", maps = M.mode_search },
        { [[f,]], n, "clear search", rhs = "<cmd>nohlsearch<enter>" },
        { [[f ]], n, "activate", rhs = "<cmd>set hlsearch<enter>", maps = M.mode_search },
        -- { [[<a-u>]], n, "previous match", rhs = "Nzz" },
        -- { [[<a-e>]], n, "next match", rhs = "nzz" },
    }
end

---@type ModeFn
function M.mode_windows()
    local layouts = require("lavish-layouts")
    local maps = validated_maps {
        { [[u]], n, "previous window", fn = layouts.previous },
        { [[e]], n, "next window", fn = layouts.next },
        { [[n]], n, "focus window", fn = layouts.focus, maps = M.mode_default },
        { [[f]], n, "focus window", fn = layouts.focus, maps = M.mode_default },
        { [[i]], n, "close window", fn = layouts.close },
        { [[c]], n, "close window", fn = layouts.close },
        { [[,]], n, "close window", fn = layouts.close },
        { [[d]], n, "close window and delete buffer", fn = layouts.close_and_delete },
        { [[<esc>]], n, "end windows", maps = M.mode_default },
        { [[w]], n, "end windows", maps = M.mode_default },
    }
    return "windows", maps
end

local stack = {}

function M.get_stack_size()
    return #stack
end

local function stack_push()
    local file = vim.api.nvim_buf_get_name(0)
    local cursor = vim.api.nvim_win_get_cursor(0)
    table.insert(stack, { file = file, cursor = cursor })
end

local function stack_pop()
    local at = table.remove(stack)
    if not at then
        return
    end
    vim.cmd.edit(at.file) -- TODO could need escapes
    vim.api.nvim_win_set_cursor(0, at.cursor) -- TODO marks would be better, because they move as text changes
end

---@return Map[] mappings
function M.for_windows()
    local layouts = require("lavish-layouts")
    return validated_maps {
        { [[w]], n, "windows" },
        { [[ww]], n, "new window", fn = layouts.new_from_split },
        { [[wu]], n, "previous window", fn = layouts.previous, maps = M.mode_windows },
        { [[we]], n, "next window", fn = layouts.next, maps = M.mode_windows },
        { [[w ]], n, "focus window", fn = layouts.focus },
        { [[w,]], n, "close window", fn = layouts.close }, -- [[wc]]
        { [[w.]], n, "only window", rhs = "<cmd>wincmd o<enter>" },
        { [[wd]], n, "close window and delete buffer", fn = layouts.close_and_delete },

        -- tabs
        -- { [[w  ]], n, "new tab", rhs = "<cmd>tab split<enter>" },
        -- { [[w ,]], n, "close tab", rhs = "<cmd>tabclose<enter>" },
        -- { [[w .]], n, "only tab", rhs = "<cmd>tabonly<enter>" },
        -- { [[w n]], n, "previous tab", rhs = "<cmd>-tabnext<enter>" },
        -- { [[w i]], n, "next tab", rhs = "<cmd>+tabnext<enter>" },

        -- layouts
        { [[wlm]], n, "layout main", fn = layouts.switch_main },
        { [[wls]], n, "layout stacked", fn = layouts.switch_stacked },

        -- trying out stacks
        { [[wm]], n, "stack push", fn = stack_push },
        { [[wo]], n, "stack pop", fn = stack_pop },

        -- hacky shorts
        {
            [[wt]],
            n,
            "new window and t...",
            fn = function()
                layouts.new_from_split()
                vim.fn.feedkeys("t")
            end,
        },
    }
end

---@return Map[] mappings
function M.for_jumps()
    -- TODO want to make this generic, and dynamic
    local t = require("yi.telescope")
    local l = require("yi.lsp")

    return validated_maps {
        { [[t]], n, "jumps" },

        { [[tr]], n, "jump to references", fn = t.pick_references },
        -- map { [[tar]], n, "jump to previous references", fn = t.pick_previous_references }, -- use resume instead?
        -- TODO wrong place a bit
        { [[E]], n, "next entry", rhs = "<cmd>cn<enter>" },
        { [[U]], n, "previous entry", rhs = "<cmd>cN<enter>" },
        {
            [[a.]],
            n,
            "show lsp hover",
            fn = function()
                -- TODO cant find where we can set those defaults
                vim.lsp.buf.hover { border = "double", anchor_bias = "above" }
            end,
        },
        {
            [[a,]],
            n,
            "show diagnostic",
            fn = vim.diagnostic.open_float,
        },
        -- TODO would be nicer to have the same binding to toggle
        { [[=]], n, "highlight references", fn = l.highlight_references },
        { [[?]], n, "clear highlight references", fn = l.clear_highlight_references },
        -- TODO range actions also exist, not the same as union of actions, more like "make try except" and stuff
        { [[a;]], n, "code action", fn = l.code_action },
        { [[a;]], v, "code action", fn = l.code_action },
        { [[a_]], n, "toggle inlay hints", fn = l.toggle_inlay_ints },
        { [[<F11-t>]], i, "show function signature", fn = l.show_function_signature },
        -- TODO again this would be better just a command behind a lsp prefix, like for layouts?
        { [[ao]], n, "rename symbol", fn = l.rename_symbol },
        { [[ai]], n, "add ignore", fn = l.add_ignore },

        -- only rust atm
        { [[ad]], n, "open docs in browser", fn = l.goto_docs_browser },
        { [[a?]], n, "explain error", fn = l.explain_error },
        { [[ar]], n, "render diagnostic", fn = l.open_diagnostic },
        { [[ap]], n, "open package file", fn = l.open_pkg_manager },

        { [[tt]], n, "definition", fn = l.go_to_definition },
        { [[t ]], n, "resume", fn = t.pick_resume },
        { [[tn]], n, "files", fn = t.pick_file },
        { [[tg]], n, "live grep", fn = t.pick_grep },
        { [[tc]], n, "files diff to main", fn = t.pick_diff_files },
        { [[tb]], n, "buffers", fn = t.pick_buffer },
        { [[th]], n, "help tags", fn = t.pick_help },
        { [[tk]], n, "man pages", fn = t.pick_man },
        { [[tak]], n, "all man pages", fn = t.pick_man_all },
        { [[tm]], n, "marks", fn = t.pick_mark },
        { [[tj]], n, "jumps", fn = t.pick_jumplist },
        { [[tfc]], n, "config files", fn = t.pick_file_config },
        { [[te]], n, "buffer symbols", fn = t.pick_buffer_symbol },
        { [[tu]], n, "project symbols", fn = t.pick_project_symbol },

        {
            [[tdd]],
            n,
            "jump to next diagnostic",
            fn = function()
                vim.diagnostic.jump { count = 1, float = true, severity = { min = vim.diagnostic.severity.ERROR } }
            end,
        },

        { [[tde]], n, "buffer diagnostics", fn = t.pick_buffer_diagnostics },
        { [[tdae]], n, "buffer all diagnostics", fn = t.pick_buffer_diagnostics_all },
        { [[tdu]], n, "project diagnostics", fn = t.pick_project_diagnostics },
        { [[tdau]], n, "project all diagnostics", fn = t.pick_project_diagnostics_all },
    }
end

-- TODO comma is already used for last insert maybe?
-- TODO call it misc?
function M.for_comma()
    local function reset_view_and_format()
        vim.cmd([[normal! 0^]])
        require("yi.formatter").format_buffer()
    end
    local g = require("yi.fugitive")
    local h = require("hop")
    return validated_maps {
        { [[,]], n, "misc" },
        -- map { [[,x]], n, "(try) save and exit (anyway)", rhs = "<cmd>silent! wa<enter><cmd>qa!<enter>" },
        { [[<c-d>]], ni, "(try) save and exit (anyway)", rhs = "<cmd>silent! wa<enter><cmd>qa!<enter>" },
        { [[<c-s>]], ni, "save", rhs = "<cmd>silent! w<enter>" },

        -- formatter and git
        { [[==]], n, "format buffer", fn = reset_view_and_format },
        { [[gn]], n, "git", fn = g.git },

        -- hop
        { [[  ]], n, "hop 2char", fn = h.hint_char2 },
        { [[  ]], v, "hop 2char", fn = h.hint_char2 },
        -- TODO fixme if still needed?
        -- map {
        --     [[<F11>]],
        --     i,
        --     "jump on same line in insert mode",
        --     expr = todo h.hint_char1 {
        --         direction = require("hop.hint").HintDirection.AFTER_CURSOR,
        --         current_line_only = true,
        --     },
        -- },

        -- term aliases
        { [[,g]], n, "run .tmux/g", rhs = ":vsplit | term zsh -c '$(pwd)/.tmux/g'<CR>" },
        { [[<ESC>]], "t", "normal mode (term)", rhs = [[<C-\><C-n>]] },
    }
end

function M.for_undos()
    return validated_maps {
        { [[<c-w>]], n, "undo", rhs = "u" },
        { [[<c-f>]], n, "redo", rhs = "<c-r>" },
    }
end

function M.for_completion()
    local c = require("yi.completion")
    return validated_maps {
        { [[<c-t>]], i, "complete flat", fn = c.complete_flat },
        { [[<c-l>]], i, "complete full", fn = c.complete_full },
    }
end

function M.operatorfunc_comments(mode)
    require("vim._comment").operator(mode)
    vim.cmd([[normal! `z]])
end

function M.for_comments()
    -- see https://github.com/neovim/neovim/blob/d01b2611a6d54ec20640ddab4149932bd9213b7b/runtime/lua/vim/_defaults.lua#L170

    local function operation()
        -- TODO this could be done generically to reset cursor positions after operators? just wrap it?
        vim.o.operatorfunc = [[v:lua.require'yi.mappings'.operatorfunc_comments]]
        -- NOTE marks to keep the cursor in place
        return "mzg@"
    end

    local function visual()
        -- NOTE marks to keep the cursor in place
        return "mz" .. require("vim._comment").operator() .. "`z"
    end

    return validated_maps {
        { [[,c]], n, "comment with operator", expr = operation },
        { [[,c]], v, "comment visual", expr = visual },
    }
end

return M
