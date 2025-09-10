;; extends

;; also want to do something for doc_comment
;; TODO also how to set style/colors?
;; vim.api.nvim_set_hl(0, "@comment.documentation", { fg = "#7c7c7c" })

(
  (line_comment) @comment.todo
  (#match? @comment.todo "TODO")
  (#set! priority 126)
)

(
  (line_comment) @comment.note
  (#match? @comment.note "NOTE")
  (#set! priority 126)
)
