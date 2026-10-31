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
