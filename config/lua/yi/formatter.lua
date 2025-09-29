local M = {}

function M.format_buffer()
    local formatter = require("funky-formatter")
    formatter.format()
end

function M.setup()
    local formatter = require("funky-formatter")
    local c = formatter.configs
    local from_cmds = formatter.from_cmds
    local path_token = formatter.path_token

    formatter.setup {
        python = c.python_ruff_ruff,
        lua = c.lua_stylua,
        json = c.json_jq,
        yaml = c.yaml_prettier,
        html = c.html_prettier,
        rust = c.rust_rustfmt,
        gitignore = c.gitignore_sort,
        nix = c.nix_nixpkgsfmt,
        toml = c.toml_taplo,
        css = from_cmds { { "prettier", "--parser", "css", path_token } },
        graphql = from_cmds { { "prettier", "--parser", "graphql", path_token } },
        javascript = from_cmds { { "prettier", "--parser", "javascript", path_token } },
        typescript = from_cmds { { "prettier", "--parser", "typescript", path_token } },
        typescriptreact = from_cmds { { "prettier", "--parser", "typescriptreact", path_token } },
        markdown = from_cmds { { "prettier", "--parser", "markdown", path_token } },
    }
end

return M
