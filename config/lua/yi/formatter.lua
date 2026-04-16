local M = {}

function M.format_buffer()
    local formatter = require("funky-formatter")
    formatter.format()
end

function M.setup()
    local formatter = require("funky-formatter")
    local c = formatter.configs
    local from_cmds = formatter.from_cmds
    local from_stdout = formatter.from_stdout
    local path_token = formatter.path_token

    formatter.setup {
        python = c.python_ruff_ruff,
        lua = c.lua_stylua,
        json = c.json_jq,
        yaml = c.yaml_prettier,
        html = c.html_prettier,
        gitignore = c.gitignore_sort,
        nix = c.nix_nixfmt,
        toml = c.toml_taplo,
        rust = from_cmds { { "rustfmt", path_token } },
        cpp = from_stdout { "clang-format", path_token },
        cuda = from_stdout { "clang-format", path_token },
        css = from_stdout { "prettier", "--parser", "css", path_token },
        graphql = from_stdout { "prettier", "--parser", "graphql", path_token },
        markdown = from_stdout {
            "prettier",
            "--prose-wrap",
            "always",
            "--print-width",
            "80",
            "--parser",
            "markdown",
            path_token,
        },
        -- TODO should use biome
        javascript = from_stdout {
            "prettier",
            "--write",
            "--log-level",
            "silent",
            "--parser",
            "javascript",
            path_token,
        },
        typescript = from_stdout { "prettier", "--parser", "typescript", path_token },
        typescriptreact = from_stdout {
            "prettier",
            "--parser",
            "typescript",
            path_token,
        },
        typst = from_stdout {
            "typstyle",
            "--wrap-text",
            path_token
        }
    }
end

return M
