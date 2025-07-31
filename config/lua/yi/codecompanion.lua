local mod = {}

function mod.setup()
    ---@diagnostic disable-next-line: redundant-parameter
    require("codecompanion").setup {
        strategies = {
            chat = {
                adapter = "anthropic",
                keymaps = {
                    send = {
                        modes = { n = "<C-s>", i = "<C-s>" },
                        opts = {},
                    },
                    close = {
                        modes = { n = "<C-c>", i = "<C-c>" },
                        opts = {},
                    },
                },
                variables = {
                    ["buffer"] = {
                        callback = "strategies.chat.variables.buffer",
                        description = "Share the current buffer with the LLM",
                        opts = {
                            contains_code = true,
                            default_params = "watch",
                            has_params = true,
                        },
                    },
                },
                slash_commands = {
                    ["file"] = {
                        callback = "strategies.chat.slash_commands.file",
                        description = "Select a file using Telescope",
                        opts = {
                            provider = "telescope",
                            contains_code = true,
                        },
                    },
                },
            },
            inline = {
                adapter = "anthropic",
            },
            cmd = {
                adapter = "anthropic",
            },
        },
        adapters = {
            anthropic = function()
                return require("codecompanion.adapters").extend("anthropic", {
                    env = {
                        api_key = "cmd:op read op://personal/anthropic/credential --no-newline",
                    },
                })
            end,
        },
    }
end

return mod
