# Shared setup, sourced at the top of every chapter -----------------------------
# Quarto renders each chapter in a fresh R session, so nothing defined in one
# chapter is available in the next. Load packages, helpers, and shared data
# here instead, and start each chapter with a setup chunk:
#
#   ```{r}
#   #| label: setup-<chapter>
#   source("_common.R")
#   ```

options(tidyverse.quiet = TRUE)

library(tidyverse)
library(ratlas)
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

# gt tables --------------------------------------------------------------------
gt_atlas <- function(
  data,
  dec_dig = 1,
  corr_dig = 3,
  fmt_extreme = TRUE,
  ...
) {
  # general formatting -----
  data <- data |>
    gt::cols_align_decimal(columns = dplyr::where(is.numeric))

  # number formatting -----
  data <- data |>
    ## integers
    gt::fmt_number(columns = dplyr::where(is.integer), decimals = 0) |>

    ## numerics
    gt::fmt_number(
      columns = dplyr::where(\(x) {
        is.double(x) && !all(dplyr::between(x, -1, 1))
      }),
      decimals = dec_dig
    ) |>

    ## proportions and correlations bounded [-1, 1]
    gt::fmt_number(
      columns = dplyr::where(\(x) {
        is.double(x) && all(dplyr::between(x, -1, 1))
      }),
      decimals = corr_dig
    )

  # extreme value formatting -----
  if (fmt_extreme) {
    data <- data |>
      gt::sub_small_vals(
        columns = dplyr::where(\(x) {
          is.double(x) && !all(dplyr::between(x, -1, 1))
        }),
        threshold = 1 / (10^dec_dig)
      ) |>
      gt::sub_large_vals(
        columns = dplyr::where(\(x) {
          is.double(x) && !all(dplyr::between(x, -1, 1))
        }),
        threshold = 100 - (1 / (10^dec_dig)),
        large_pattern = ">{x}"
      ) |>
      gt::sub_large_vals(
        columns = dplyr::where(\(x) {
          is.double(x) && all(dplyr::between(x, -1, 1))
        }),
        threshold = 1 - (1 / (10^corr_dig)),
        large_pattern = ">{x}"
      ) |>
      gt::sub_large_vals(
        columns = dplyr::where(\(x) {
          is.double(x) && all(dplyr::between(x, -1, 1))
        }),
        threshold = 1 - (1 / (10^corr_dig)),
        large_pattern = "<\U2212{x}",
        sign = "-"
      )
  }

  # group formatting -----
  if (length(data$`_row_groups`)) {
    data <- data |>
      gt::tab_style(
        style = gt::cell_text(indent = gt::px(20)),
        locations = gt::cells_body(
          columns = 1,
          rows = gt::everything()
        )
      )
  }

  # table styling -----
  data <- data |>
    gt::text_transform(
      fn = \(x) gsub("0\\.", ".", x),
      locations = gt::cells_body(
        columns = dplyr::where(\(x) {
          is.double(x) && all(dplyr::between(x, -1, 1))
        }),
        rows = gt::everything()
      )
    ) |>
    gt::tab_options(
      table.align = "left",
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(align = "center", v_align = "middle")
      ),
      locations = gt::cells_column_labels(gt::everything())
    )

  data
}
