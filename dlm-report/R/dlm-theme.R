# DLM brand colors ---------------------------------------------------------------
# Colors are taken from the DLM slide template so figures match the website,
# the PDF, and presentations. Figures use ratlas::theme_atlas() (set as the
# default theme in _common.R) with the DLM ink, accent, and continuous ramp.
# Use these colors directly for single-color marks, outlines, and annotations.

dlm_colors <- c(
  navy   = "#003459",
  blue   = "#0051BA",
  bright = "#2767FF",
  sky    = "#73CBF2",
  mist   = "#DDE5ED",
  ink    = "#1B2733",
  muted  = "#5A6B7B"
)

# Output format helpers ------------------------------------------------------
# Use these in inline R to write format-specific text, for example
# `r if (dlm_is_pdf()) "this report" else "this website"`.

#' TRUE when rendering the Typst PDF
dlm_is_pdf <- function() {
  isTRUE(knitr::pandoc_to("typst"))
}

#' TRUE when rendering the HTML website
dlm_is_html <- function() {
  isTRUE(knitr::is_html_output())
}
