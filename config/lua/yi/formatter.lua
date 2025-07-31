local M = {}

function M.format_buffer()
    local formatter = require("funky-formatter")
    formatter.format()
end

function M.setup()
    local formatter = require("funky-formatter")
    formatter.setup {
        -- TODO was pyformat
        python = function(path)
            path = vim.fn.shellescape(path)
            return {
                "zsh",
                "-c",
                "ruff check --fix-only --select I --silent " .. path .. " | ruff format " .. path,
            }
        end,
        lua = function(path)
            return { "stylua", "--search-parent-directories", path }
        end,
        json = function(path)
            return { "jq", ".", path }
        end,
        yaml = function(path)
            return { "prettier", "--parser", "yaml", path }
        end,
        html = function(path)
            return { "prettier", "--parser", "html", path }
        end,
        css = function(path)
            return { "prettier", "--parser", "css", path }
        end,
        graphql = function(path)
            return { "prettier", "--parser", "graphql", path }
        end,
        javascript = function(path)
            return { "prettier", "--parser", "typescript", path }
        end,
        typescript = function(path)
            return { "prettier", "--parser", "typescript", path }
        end,
        typescriptreact = function(path)
            return { "prettier", "--parser", "typescript", path }
        end,
        rust = function(path)
            return { "rustfmt", path }
        end,
        markdown = function(path)
            return { "prettier", "--parser", "markdown", path }
        end,
        gitignore = function(path)
            return { "env", "-", "LC_ALL=C", "sort", "--unique", path }
        end,
        ["requirements.in"] = function(path)
            return { "env", "-", "LC_ALL=C", "sort", "--unique", path }
        end,
        ["requirements-dev.in"] = function(path)
            return { "env", "-", "LC_ALL=C", "sort", "--unique", path }
        end,
        nix = function(path)
            return { "nixpkgs-fmt", path }
        end,
        toml = function(path)
            -- TODO taplo also has an lsp, nice if we use it for papers notes?
            -- TODO different defaults for non-nn stuff?
            return { "taplo", "fmt", "--option", "indent_string=    ", path }
        end,
    }
end

return M
