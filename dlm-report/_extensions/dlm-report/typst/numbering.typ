// DLM numbering helpers --------------------------------------------------------
// Floats (figures, tables, listings, callouts) and equations are numbered with
// the chapter prefix in books ("3.2") and appendix letters in appendices
// ("B.1"). The chapter is encoded into the counter itself
// (chapter * 1000 + n, appendices offset by 500 chapters), so the numbers are
// the same wherever they are displayed: captions, cross-references, and the
// lists of figures and tables. In single-document reports the chapter part is
// zero and numbers are flat ("1", "2", ...).

#let dlm-chapter-prefix(c) = {
  if c >= 500 { numbering("A", c - 500) } else { str(c) }
}

#let dlm-float-number(n) = {
  let c = calc.quo(n, 1000)
  let k = calc.rem(n, 1000)
  if c == 0 { str(k) } else { dlm-chapter-prefix(c) + "." + str(k) }
}

// Equation numbers use the text font, not the math font. Quarto passes this
// function to each numbered equation directly, so it sets the font itself.
#let dlm-text-font = state("dlm-text-font", none)
#let equation-numbering = n => context {
  let label = "(" + dlm-float-number(n) + ")"
  let font = dlm-text-font.get()
  if font == none { label } else { text(font: font, label) }
}
#let callout-numbering = n => dlm-float-number(n)
#let subfloat-numbering(n-super, subfloat-idx) = {
  dlm-float-number(n-super) + numbering("a", subfloat-idx)
}

// Theorem configuration for theorion (chapter-based in books)
#let theorem-inherited-levels = 1
#let theorem-numbering(loc) = {
  if state("appendix-state", none).at(loc) != none { "A.1" } else { "1.1" }
}
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  block(width: 100%, inset: (left: 1em), stroke: (left: 2pt + rgb("#0051BA")))[
    #if full-title != "" and full-title != auto and full-title != none {
      strong[#full-title]
      linebreak()
    }
    #body
  ]
}
