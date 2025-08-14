if exists("b:current_syntax")
    finish
endif

syntax match noteSection "\v^[^- ].*:$"
syntax match noteSectionDone "\v^[^- ].*;$"
syntax match noteTodo "\v^ *o \zs.*\ze$"
syntax match noteDone "\v^ *x \zs.*\ze$"
syntax match noteCancel "\v^ *c \zs.*\ze$"
syntax match noteNow "\v^ *! \zs.*\ze$"
syntax match noteRunning "\v^ *r \zs.*\ze$"

lua << EOF
local palette = require('nightfox.palette').load("nordfox")
vim.cmd('highlight noteSection gui=underline,bold guifg=' .. palette.fg1 .. ' guibg=' .. palette.bg1)
vim.cmd('highlight noteSectionDone gui=underline,strikethrough,bold guifg=' .. palette.fg1 .. ' guibg=' .. palette.bg1)
vim.cmd('highlight noteTodo gui=bold guifg=' .. palette.fg1)
vim.cmd('highlight noteDone gui=strikethrough guifg=' .. palette.comment)
vim.cmd('highlight noteCancel gui=strikethrough guifg=' .. palette.comment)
vim.cmd('highlight noteNow guifg=' .. palette.bg1 .. ' guibg=' .. palette.orange.base)
vim.cmd('highlight noteRunning gui=italic guifg=' .. palette.blue.base)
EOF

let b:current_syntax = "note"
