;; extends

; Call-site keyword arguments: paint them the way basedpyright does.
;
; nvim-treesitter captures the name in `Point(label="a")` as @variable.parameter,
; which poimandres leaves at the plain text colour; basedpyright sends a
; "property" semantic token for the same range, and @lsp.type.property links to
; @property = #ADD7FF. Semantic tokens sit at priority 125 against treesitter's
; 100, so the server always wins -- but only once its answer for the CURRENT
; buffer version arrives (vim/lsp/semantic_tokens.lua drops results whose
; version does not match). While you type an argument list every keystroke
; invalidates that, so each field name turned blue a beat late, in practice not
; until the call was finished. Capturing it as @variable.member here gives
; treesitter the same colour up front, so nothing changes when the tokens land.
(keyword_argument
  name: (identifier) @variable.member)
