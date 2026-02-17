local M = {}

function M.setup()
    -- require("dapui").setup()
    local dap = require("dap")

    dap.adapters.lldb = {
        type = "executable",
        command = "lldb-dap",
        name = "lldb",
    }

    dap.configurations.rust = {
        {
            name = "Launch",
            type = "lldb",
            request = "launch",
            program = function()
                return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = {},
        },
    }
end

return M
