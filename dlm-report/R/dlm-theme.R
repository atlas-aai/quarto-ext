# DLM brand helpers for ggplot2 ------------------------------------------------
# Colors are taken from the DLM slide template so figures match the website,
# the PDF, and presentations.

dlm_colors <- c(
  navy   = "#003459",
  blue   = "#0051BA",
  bright = "#2767FF",
  sky    = "#73CBF2",
  mist   = "#DDE5ED",
  ink    = "#1B2733",
  muted  = "#5A6B7B"
)

#' Look up DLM colors by name
#' @param x Character vector of color names (see `names(dlm_colors)`).
dlm_palette <- function(x = c("navy", "blue", "sky", "bright")) {
  unname(dlm_colors[x])
}

#' Discrete fill/colour scales using the DLM categorical order
scale_fill_dlm <- function(...) {
  ggplot2::scale_fill_manual(values = dlm_palette(c("navy", "blue", "sky", "bright", "muted")), ...)
}
scale_colour_dlm <- function(...) {
  ggplot2::scale_colour_manual(values = dlm_palette(c("navy", "blue", "sky", "bright", "muted")), ...)
}
scale_color_dlm <- scale_colour_dlm

#' A clean ggplot2 theme that matches the DLM report formats
#' @param base_size Base font size in points.
#' @param base_family Font family. "Inter" is bundled with the Quarto
#'   extension; install it locally for exact matches in figures.
theme_dlm <- function(base_size = 11, base_family = "") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = dlm_colors[["ink"]]),
      axis.text = ggplot2::element_text(colour = dlm_colors[["muted"]]),
      axis.title = ggplot2::element_text(colour = dlm_colors[["ink"]], face = "bold", size = ggplot2::rel(0.9)),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = dlm_colors[["mist"]], linewidth = 0.4),
      axis.line.x = ggplot2::element_line(colour = dlm_colors[["navy"]], linewidth = 0.5),
      legend.position = "top",
      legend.justification = "left",
      legend.key.size = ggplot2::unit(0.9, "lines"),
      strip.text = ggplot2::element_text(face = "bold", colour = dlm_colors[["navy"]], hjust = 0),
      plot.title.position = "plot",
      plot.margin = ggplot2::margin(6, 10, 6, 6)
    )
}

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
