local M = {}

local function get_std_docs_path()
    local rustc = os.getenv("RUSTC") or "rustc"
    local result = vim.system({ rustc, "--print", "sysroot" }, { text = true }):wait()
    if result.code ~= 0 then
        return nil, "rustc --print sysroot failed: " .. (result.stderr or "unknown error")
    end

    local sysroot = vim.trim(result.stdout)
    local docs_path = vim.fs.joinpath(sysroot, "share/doc/rust/html/std")
    if vim.fn.isdirectory(docs_path) == 0 then
        return nil, "docs not found at " .. docs_path
    end

    return docs_path
end

local function parse_symbol(crate_root, crate_name, filepath)
    local relative = filepath:sub(#crate_root + 2)
    if relative:match("index%.html$") or relative:match("all%.html$") or relative:match("sidebar%-items") then
        return nil
    end

    local filename = vim.fn.fnamemodify(relative, ":t")
    local kind, name = filename:match("^(%w+)%.(.+)%.html$")
    if not kind or not name then
        return nil
    end

    local dir = vim.fn.fnamemodify(relative, ":h")
    local module_path
    if dir == "." then
        module_path = crate_name
    else
        module_path = crate_name .. "::" .. dir:gsub("/", "::")
    end

    return {
        display = module_path .. "::" .. name .. " [" .. kind .. "]",
        path = filepath,
    }
end

local function collect_symbols(crate_root, crate_name)
    -- TODO vim.fn.glob blocks the UI; to fix, replace with a recursive vim.uv.fs_scandir?
    local files = vim.fn.glob(crate_root .. "/**/*.html", false, true)
    local symbols = {}
    for _, filepath in ipairs(files) do
        local symbol = parse_symbol(crate_root, crate_name, filepath)
        if symbol then
            table.insert(symbols, symbol)
        end
    end
    return symbols
end

local function list_all_symbols()
    local symbols = {}

    local docs_path, err = get_std_docs_path()
    if docs_path then
        table.insert(symbols, { display = "std [crate]", path = docs_path .. "/index.html" })
        vim.list_extend(symbols, collect_symbols(docs_path, "std"))
    elseif err then
        vim.notify(err, vim.log.levels.WARN)
    end

    -- get repo root from lsp (for local docs)
    local clients = vim.lsp.get_clients { bufnr = 0, name = "rust_analyzer" }
    local root = clients[1] and clients[1].root_dir or vim.fn.getcwd()
    local target_doc = root .. "/target/doc"
    if vim.fn.isdirectory(target_doc) == 1 then
        local entries = vim.fn.glob(target_doc .. "/*", false, true)
        for _, entry in ipairs(entries) do
            if vim.fn.isdirectory(entry) == 1 then
                local crate_name = vim.fn.fnamemodify(entry, ":t")
                if crate_name ~= "src" and crate_name ~= "static.files" and not crate_name:match("^%.") then
                    table.insert(symbols, { display = crate_name .. " [crate]", path = entry .. "/index.html" })
                    vim.list_extend(symbols, collect_symbols(entry, crate_name))
                end
            end
        end
    end

    table.sort(symbols, function(a, b)
        return a.display < b.display
    end)
    return symbols
end

function M.pick_docs()
    local symbols = list_all_symbols()
    if #symbols == 0 then
        vim.notify("no rust docs found", vim.log.levels.ERROR)
        return
    end

    local items = vim.tbl_map(function(symbol)
        return { text = symbol.display, file = symbol.path }
    end, symbols)

    require("snacks.picker").pick {
        title = "Rust docs",
        items = items,
        format = function(item)
            return { { item.text } }
        end,
        layout = {
            layout = {
                backdrop = false,
                width = 0.6,
                height = 0.8,
                box = "vertical",
                border = "rounded",
                title = "{title}",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
            },
        },
        confirm = function(picker, item)
            picker:close()
            -- tried rendering docs in a scratch buffer via pandoc; rustdoc HTML is too noisy
            -- to clean up fully
            -- local html = table.concat(vim.fn.readfile(item.file), "\n")
            -- html = html:gsub('<span class="sub%-heading">.-</span>', "")
            -- html = html:gsub('<a[^>]*href="https://play%.rust%-lang%.org/[^"]*"[^>]*>.-</a>', "")
            -- html = html:gsub('<a[^>]*class="doc%-anchor"[^>]*>.-</a>', "")
            -- local result = vim.system(
            --     { "pandoc", "-f", "html", "-t", "markdown_strict" },
            --     { text = true, stdin = html }
            -- ):wait()
            -- if result.code ~= 0 or not result.stdout or result.stdout == "" then
            --     vim.notify("pandoc failed to convert docs", vim.log.levels.ERROR)
            --     return
            -- end
            -- local lines = vim.split(result.stdout, "\n", { plain = true })
            -- local layouts = require("lavish-layouts")
            -- layouts.new_from_split()
            -- local buf = vim.api.nvim_create_buf(false, true)
            -- vim.bo[buf].buftype = "nofile"
            -- vim.bo[buf].bufhidden = "wipe"
            -- vim.bo[buf].filetype = "markdown"
            -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            -- vim.bo[buf].modifiable = false
            -- vim.api.nvim_win_set_buf(0, buf)
            vim.system { "firefox", "--new-window", "file://" .. item.file }
        end,
    }
end

return M
