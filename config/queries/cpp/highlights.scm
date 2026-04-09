;; extends

(
  (comment) @comment.documentation
  (#match? @comment.documentation "^(//[/!]|/\\*[*!])")
  (#set! priority 126)
)
(
  (comment) @comment.line
  (#match? @comment.line "^//[^/!]")
  (#offset! @comment.line 0 2 0 0)
  (#set! priority 126)
)
