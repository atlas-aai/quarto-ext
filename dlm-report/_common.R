# Shared setup, sourced at the top of every chapter -----------------------------
# Quarto renders each chapter in a fresh R session, so nothing defined in one
# chapter is available in the next. Load packages, helpers, and shared data
# here instead, and start each chapter with a setup chunk:
#
#   ```{r}
#   #| label: setup-<chapter>
#   source("_common.R")
#   ```

library(ggplot2)
library(gt)

source("R/dlm-theme.R")

# Figures use the report font, Atkinson Hyperlegible Next. If it isn't
# installed, register the copy bundled with the extension; ragg can draw
# registered fonts.
if (!"Atkinson Hyperlegible Next" %in% systemfonts::system_fonts()$family) {
  font_dir <- "_extensions/dlm-report/fonts/ttf"
  systemfonts::register_font(
    name = "Atkinson Hyperlegible Next",
    plain = file.path(font_dir, "AtkinsonHyperlegibleNext-Regular.ttf"),
    bold = file.path(font_dir, "AtkinsonHyperlegibleNext-Bold.ttf"),
    italic = file.path(font_dir, "AtkinsonHyperlegibleNext-Italic.ttf"),
    bolditalic = file.path(font_dir, "AtkinsonHyperlegibleNext-BoldItalic.ttf")
  )
}
knitr::opts_chunk$set(dev = "ragg_png")

# Figures: the ATLAS ggplot2 theme with DLM colors for text, accents, and
# continuous scales. Discrete scales use theme_atlas()'s Okabe-Ito palette,
# which is colorblind safe.
set_theme(ratlas::theme_atlas(
  base_family = "Atkinson Hyperlegible Next",
  ink = dlm_colors[["ink"]],
  accent = dlm_colors[["blue"]],
  continuous = unname(dlm_colors[c("mist", "navy")])
))
