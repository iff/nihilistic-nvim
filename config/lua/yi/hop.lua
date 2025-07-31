local mod = {}

function mod.setup()
    local hop = require("hop")
    hop.setup {
        multi_windows = true, -- this means more targets, potentially longer sequence to reach
        char2_fallback_key = "<enter>",
        jump_on_sole_occurrence = true,
        -- based on https://colemakmods.github.io/mod-dh/model.html
        keys = "ntseriufhdywoa",
    }
end

return mod
