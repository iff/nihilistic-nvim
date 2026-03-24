;; extends

(
  (doc_comment) @comment.documentation
  (#set! priority 126)
)
(
  (line_comment !doc) @comment.line
  (#offset! @comment.line 0 2 0 0)
  (#set! priority 126)
)

