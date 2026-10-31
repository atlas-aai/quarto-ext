# Development only: not part of the dlm-report template.
#
# Chapters run `source("_common.R")`, which resolves from the Quarto project
# root. `quarto render` already runs from dlm-report/ (execute-dir: project),
# and template users have _common.R at their project root. Interactive R
# sessions opened on this repository start one level up, so move into the
# example project to run chunks the same way.

# A project .Rprofile replaces the user's, so keep theirs
if (file.exists("~/.Rprofile")) source("~/.Rprofile")

if (interactive() && file.exists("dlm-report/_common.R")) {
  setwd("dlm-report")
  message("Working directory set to dlm-report/ (see .Rprofile)")
}
