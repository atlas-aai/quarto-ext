$-- Citations and the reference list are formatted by Pandoc's citeproc with the
$-- document's `csl` (see _extension.yml), so the website and the PDF match.
$-- citeproc fills the `::: {#refs}` div (styled in dlm-report.lua) or appends
$-- the list to the end of the document. This partial replaces Quarto's default,
$-- which would add a second, Typst-native bibliography.
