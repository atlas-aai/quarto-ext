# DLM Report: Quarto extension and template

A Quarto extension for Dynamic Learning Maps technical manuals and research reports. One source renders two outputs:

- **`dlm-report-html`**: a modern, searchable website (light and dark modes) with a cover hero, a "Download PDF" button, and the same chapter structure as the PDF.
- **`dlm-report-typst`**: a typeset PDF built with Typst, with a branded cover, colophon, contents, lists of tables and figures, chapter openers, running heads, and the navy page tab from the DLM slide template.

The design follows the DLM PowerPoint template: the navy, blue, sky, and mist palette, the rotated rounded-square ornaments, and the DLM logo placement.

Requires Quarto 1.9.17 or later (tested with Quarto 1.10.20 and Typst 0.15). No LaTeX installation is needed.

## Start a new report

```bash
quarto use template atlas-aai/quarto-ext/dlm-report
```

This copies the extension and the starter technical manual in the repository. To add the extension to an existing project instead:

```bash
quarto add atlas-aai/quarto-ext/dlm-report
```

Render both formats with `quarto render`. The website and the PDF land in `_book/`. Use `quarto preview` while writing.

## Project types

**Technical manual (Quarto book).** The starter project in this repository is a book. Each chapter is its own page on the website and a chapter with an opener page in the PDF. Appendices are lettered (Appendix A, Table A.1) in both formats. The website links to the PDF automatically through `book: downloads: [pdf]`.

**Research report (single document).** Use the same formats in a standalone `.qmd`. Level 1 headings become numbered sections without page breaks, and figures and tables are numbered 1, 2, 3.

```yaml
---
title: "Evaluating Linkage Level Mastery Thresholds"
subtitle: "A Simulation Study"
author:
  - name: First Author
date: 2026-10-31
dlm:
  report-type: Research Synopsis
  report-number: "No. 26-04"
format:
  dlm-report-html: default
  dlm-report-typst: default
---
```

## DLM metadata

All options live under the `dlm` key and apply to both formats.

| Option | Purpose | Default |
|:--|:--|:--|
| `report-type` | Eyebrow label on the cover ("Technical Manual", "Research Synopsis") | `Technical Report` |
| `report-number` | Report number shown on the cover | none |
| `running-title` | Short title for PDF running heads | `title` |
| `citation` | Suggested citation on the PDF colophon and the website cover | none |
| `rights` | Statement shown above the suggested citation; `false` to omit it | "**All rights reserved.** Any or all portions of this document may be reproduced…" |
| `funding` | Funding statement or disclaimer on the PDF colophon | none |
| `colophon` | Any extra text for the top of the colophon page | none |
| `copyright` | Copyright line | `Copyright © <current year>` |
| `publisher` | Publisher line under the copyright | ATLAS, University of Kansas |
| `cover` | Set to `false` to drop the PDF cover and colophon | `true` |
| `divider` | PDF divider pages before level 1 headings: `true` (every numbered chapter and appendix), `after-first` (every numbered chapter except chapter 1), or `false` (none). A divider shows the chapter number, the title, and an optional blurb. Book parts and the Appendices page use the same design. | `false` |
| `pdf-file` | PDF file name for the website button, if not the book `output-file` | book `output-file` |
| `show-pdf-button` | Set to `false` to hide the website PDF button | `true` |

Standard Quarto options still work: `toc`, `toc-depth`, `lof`, `lot`, `number-depth`, `mainfont`, `fontsize`, `bibliography`, and so on. `lof` and `lot` default to `true` for the PDF.

## Writing conventions

- Label every chapter and section (`{#sec-modeling}`) and refer to it with `@sec-modeling`.
- Label tables `tbl-*` and figures `fig-*` in code chunks. Numbers include the chapter ("Table 3.2") and are correct everywhere: captions, cross-references, and the lists of tables and figures.
- Table captions sit above tables and figure captions below figures in both formats.
- In the PDF, each table stays on one page with its caption. For a table too long for one page, add `#| classes: breakable` to its chunk (or wrap it in `::: {.breakable}`); it then splits across pages and repeats its header row, like kableExtra's `longtable`.
- Put `::: {#refs}` where the reference list belongs. Citations and references are formatted by Pandoc's citeproc with the extension's `apa.csl` (APA 7th edition, from the Zotero Style Repository) in both formats, so the website and the PDF match. Add sources to `bib/references.bib`, which `_quarto.yml` sets as the `bibliography`. To use a different style, set `csl` in `_quarto.yml`; it overrides the extension's default.
- To put text and a citation in the same parentheses, escape the semicolon: `[DCMs\; @rupp2010]` gives "(DCMs; Rupp et al., 2010)". An unescaped `;` ends the citation group.
- Wrap text in `::: {.center}` to center it, or in `::: {.hanging}` to give each paragraph a 0.5in hanging indent (as in APA references), on the website and in the PDF.
- Insert values from `_quarto.yml` with the `meta` shortcode, using dots for nested keys: `{{< meta dlm.citation >}}` inserts the suggested citation, formatting included.
- Start every chapter with a setup chunk that runs `source("_common.R")`. Quarto renders each chapter in a fresh R session, so packages, helpers, and data a chapter needs must be loaded there. Put anything shared across chapters in `_common.R`.
- Figures use `ratlas::theme_atlas()`, set as the default ggplot2 theme in `_common.R` with the DLM ink, accent, and a mist-to-navy continuous ramp. Discrete scales use its colorblind-safe Okabe-Ito palette, so plots need no theme or scale calls. Install ratlas with `pak::pak("atlas-aai/ratlas")`. `R/dlm-theme.R` provides `dlm_colors` for single-color marks and annotations.

## Heading attributes

These work on any level 1 heading and follow the conventions of the wjt-report extension.

- `# Modeling {.divider}` forces a PDF divider page for that heading, including unnumbered headings such as References.
- `# Reliability {.no-divider}` suppresses the divider for that heading.
- `# Modeling {blurb="How the models are specified and evaluated."}` adds an italic blurb. The PDF shows it under the title on the divider page. The website shows it under the chapter title. Markdown such as `*emphasis*` works inside the blurb.

Overrides and blurbs apply to one heading only and never carry into the next chapter.

## Format-specific text

Text that should differ between the website and the PDF has two options.

Quarto conditional content works for blocks and inline spans, with or without R:

```markdown
::: {.content-visible when-format="html"}
Read it chapter by chapter in the browser, or download the PDF from the button above.
:::

::: {.content-visible when-format="typst"}
The manual is also available as a searchable website.
:::

This [website]{.content-visible when-format="html"}[report]{.content-visible when-format="typst"} describes ...
```

Inline R works the same way as `knitr::is_latex_output()`. `R/dlm-theme.R` defines `dlm_is_pdf()` and `dlm_is_html()`:

```markdown
This `r if (dlm_is_pdf()) "document is" else "website hosts"` the technical manual.
```

`dlm_is_pdf()` wraps `knitr::pandoc_to("typst")`, so the call also works without the helper file.

## What is in the extension

```
_extensions/dlm-report/
├── _extension.yml        format definitions
├── dlm-report.lua        DLM metadata defaults, HTML assets, Typst asset paths, reference-list styling
├── dlm-book-typst.lua    part and appendix handling for Typst books
├── apa.csl               APA 7th edition citation style (Zotero), used by both formats
├── html/                 SCSS themes (light, dark, shared rules), cover partial, fonts CSS, small JS
├── typst/                Typst template partials (template, show, page, numbering, bibliography)
├── assets/               DLM logo (color and white), favicon, ornament SVGs
└── fonts/                Atkinson Hyperlegible Next, Fira Math, and Fira Code (SIL Open Font License): TTF/OTF for Typst and figures, WOFF2 for the web
```

Fonts are bundled so the PDF looks identical on every machine and the website does not depend on Google Fonts. The report font is Atkinson Hyperlegible Next, designed by the Braille Institute for legibility, and it is used on the website, in the PDF, and in figures. `_common.R` registers the bundled copy for figures when the font is not installed. Set `mainfont` to use a different font in the PDF. Equations use Fira Math (an OpenType math font, bundled) in the PDF and MathJax's Fira font on the website, so math matches the sans-serif text in both formats. Set `mathfont` to use a different math font in the PDF; it must be an OpenType math font such as STIX Two Math or New Computer Modern Math.

## Notes

- Render R chunks with a UTF-8 locale. In a C locale, R writes en dashes and check marks as `<U+2013>` codes.
- The PDF is a tagged PDF (Typst 0.14 and later), which helps with accessibility review.
- Typst books in Quarto require one PDF for the whole book. Quarto merges all chapters into one Typst file automatically.
