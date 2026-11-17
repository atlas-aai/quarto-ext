// =============================================================================
// DLM Report: Typst template
// Visual language follows the Dynamic Learning Maps slide template:
// navy / blue / sky / mist palette, rotated rounded-square ornaments,
// the navy page tab in the lower-left corner, and the DLM logo lower right.
// =============================================================================

#let dlm-navy   = rgb("#003459")
#let dlm-blue   = rgb("#0051BA")
#let dlm-bright = rgb("#2767FF")
#let dlm-sky    = rgb("#73CBF2")
#let dlm-mist   = rgb("#DDE5ED")
#let dlm-ink    = rgb("#1B2733")
#let dlm-muted  = rgb("#5A6B7B")
#let dlm-tint   = rgb("#F4F7FA")
#let dlm-code-bg = rgb("#F5F8FB")

#let dlm-appendix-state = state("appendix-state", none)
// Set by dlm-report.lua before every level-1 heading:
// per-heading divider override (true / false / none) and an optional blurb.
#let dlm-divider-override = state("dlm-divider-override", none)
#let dlm-divider-blurb = state("dlm-divider-blurb", none)

// Float kinds whose counters carry the chapter prefix (see numbering.typ)
#let dlm-float-kinds = (
  "quarto-float-fig", "quarto-float-tbl", "quarto-float-lst",
  "quarto-callout-Note", "quarto-callout-Warning", "quarto-callout-Caution",
  "quarto-callout-Tip", "quarto-callout-Important",
)

#let dlm-heading-numbering(..nums) = {
  let n = nums.pos()
  if n.len() <= 4 { numbering("1.1", ..n) }
}
#let dlm-appendix-heading-numbering(..nums) = {
  let n = nums.pos()
  if n.len() <= 4 { numbering("A.1", ..n) }
}

// Is the current page part of the front matter (before the body starts)?
#let dlm-in-front() = {
  let start = query(<dlm-body-start>)
  if start.len() == 0 { return false }
  here().page() < start.first().location().page()
}

// Is the current page a chapter divider page?
#let dlm-on-divider() = {
  let p = here().page()
  query(<dlm-divider>).any(m => m.location().page() == p)
}

#let dlm-rule(width: 54pt) = box(fill: dlm-sky, width: width, height: 4pt, radius: 2pt)

// Short captions ------------------------------------------------------------
// `fig-scap` / `tbl-scap` on a float: the list of figures/tables shows the
// short caption, the float itself shows the full one.
#let dlm-in-outline = state("dlm-in-outline", false)
#let dlm-flex-caption(long, short) = context {
  if dlm-in-outline.get() { short } else { long }
}

// Figure notes (`fig-note`): an APA-style note below the caption, left out of
// the list of figures.
#let dlm-fig-note(body) = context {
  if not dlm-in-outline.get() {
    block(above: 6pt, text(size: 0.9em, weight: 400, fill: dlm-muted)[#emph[Note]. #body])
  }
}

// Continued captions: a breakable table (`classes: breakable`) gets this as
// an extra first header row, so it repeats on every page the table runs onto.
// On the table's first page it is empty (the real caption is above the
// table); on later pages it repeats the caption with "(continued)".
#let dlm-continued-caption() = context {
  let figs = query(figure.where(kind: "quarto-float-tbl").before(here()))
  if figs.len() == 0 { return }
  let fig = figs.last()
  if fig.location().page() == here().page() or fig.caption == none { return }
  let num = numbering(fig.numbering, ..fig.counter.at(fig.location()))
  // padding, not block spacing: spacing at the end of a table cell is dropped
  pad(bottom: 10pt, block(width: 100%, {
    set par(justify: false, leading: 0.6em)
    set text(weight: 400, fill: dlm-ink)
    text(weight: 700, fill: dlm-navy)[#fig.supplement #num]
    h(8pt)
    fig.caption.body
    [ (continued)]
  }))
}

// Table notes (gt's tab_source_note() and tab_footnote()): the filter moves
// a table's notes out of the table into dlm-table-notes(), right after it.
// The notes are set at the table's own width (recorded by the table show
// rule below), so a long note wraps instead of widening the table; the
// table's bottom rule separates them from the table and a matching rule
// closes them. (Notes drawn by the table show rule itself would be tagged as
// part of the table, which PDF/UA rejects.) Footnote marks match the table's,
// and `size` is the table's font size (gt's tab_options(table.font.size)).
#let dlm-table-width = state("dlm-table-width", 100%)
#let dlm-table-notes(size: 1em, notes) = context block(
  width: dlm-table-width.get(),
  above: 0pt,
  inset: (x: 7pt, y: 5pt),
  stroke: (bottom: 0.8pt + dlm-navy),
  {
    set align(left)
    set text(size: size)
    set par(justify: false, leading: 0.55em)
    set block(spacing: 0.45em)
    set super(typographic: false, size: 1em, baseline: -0.3em)
    show super: set text(style: "normal")
    show super: s => if s.body == [\*] { s.body } else { s }
    notes
  },
)

// Table spanners (gt's tab_spanner()): a rule under the spanner label that
// covers only its columns. The cell inset leaves a gap between neighboring
// spanners, so the rules don't connect. The rule is placed rather than drawn
// as a full-width block: placed content doesn't count when Typst sizes
// auto-width columns, so the spanner doesn't widen the columns it covers.
#let dlm-spanner(body) = {
  pad(bottom: 4pt, body)
  place(bottom + left, line(length: 100%, stroke: 0.6pt + dlm-navy))
}

// Parts ------------------------------------------------------------------------
#let dlm-assets-state = state("dlm-assets", none)

#let dlm-part(title) = {
  pagebreak(weak: true)
  [#metadata("divider") <dlm-divider>]
  context {
    let assets = dlm-assets-state.get()
    if assets != none {
      pdf.artifact(place(top + left, dx: -1in, dy: -1.05in, image(assets + "/divider.svg", width: 8.5in, height: 11in)))
    }
  }
  place(left + top, dy: 3.2in, block(width: 4.5in, {
    set par(spacing: 0pt, leading: 0.42em)
    block(below: 18pt, text(size: 34pt, weight: 700, fill: dlm-navy, tracking: -0.015em, title))
    dlm-rule()
  }))
  pagebreak()
}

// Appendices: letters for headings, reset the chapter counter -----------------
#let dlm-appendices(title, body) = {
  counter(heading).update(0)
  dlm-appendix-state.update(title)
  set heading(numbering: dlm-appendix-heading-numbering, supplement: [Appendix])
  body
}

// Callouts (keeps Quarto's block structure so cross-referenced callouts work) -
// Important callouts get a stop-sign icon (the website swaps it in dlm.scss).
// Quarto gives important callouts this icon color and no other type uses it.
#let dlm-stop-icon(color) = box(baseline: 12%, width: 0.95em, height: 0.95em, {
  place(center + horizon, rotate(22.5deg, polygon.regular(vertices: 8, size: 0.95em, fill: color)))
  place(center + horizon, text(fill: white, weight: 900, size: 0.68em, top-edge: "cap-height", bottom-edge: "baseline")[!])
})

// Callout icons are drawn as inline SVG paths rather than Font Awesome glyphs:
// the glyphs are Unicode private-use code points, which PDF/A-2a forbids even
// inside artifacts. Quarto gives each callout type its own icon color, so the
// color picks the icon. Paths are Font Awesome 6 Free (solid), except caution,
// which uses the website's flat traffic cone (Bootstrap Icons "cone-striped")
// instead of Font Awesome's fire.
#let dlm-important-color = rgb("#CC1914")
#let dlm-caution-color = rgb("#FC5300")
#let dlm-svg-icon(viewbox, path, color) = box(baseline: 12%, pdf.artifact(image(
  bytes("<svg xmlns='http://www.w3.org/2000/svg' viewBox='" + viewbox + "'><path fill='" + color.to-hex() + "' d='" + path + "'/></svg>"),
  format: "svg",
  height: 0.95em,
)))
#let dlm-callout-icons = (
  // note: Font Awesome "info"
  (rgb("#0758E5"), "0 0 192 512", "M48 80a48 48 0 1 1 96 0A48 48 0 1 1 48 80zM0 224c0-17.7 14.3-32 32-32H96c17.7 0 32 14.3 32 32V448h32c17.7 0 32 14.3 32 32s-14.3 32-32 32H32c-17.7 0-32-14.3-32-32s14.3-32 32-32H64V256H32c-17.7 0-32-14.3-32-32z"),
  // tip: Font Awesome "lightbulb"
  (rgb("#00A047"), "0 0 384 512", "M297.2 248.9C311.6 228.3 320 203.2 320 176c0-70.7-57.3-128-128-128S64 105.3 64 176c0 27.2 8.4 52.3 22.8 72.9c3.7 5.3 8.1 11.3 12.8 17.7l0 0c12.9 17.7 28.3 38.9 39.8 59.8c10.4 19 15.7 38.8 18.3 57.5H109c-2.2-12-5.9-23.7-11.8-34.5c-9.9-18-22.2-34.9-34.5-51.8l0 0 0 0c-5.2-7.1-10.4-14.2-15.4-21.4C27.6 247.9 16 213.3 16 176C16 78.8 94.8 0 192 0s176 78.8 176 176c0 37.3-11.6 71.9-31.4 100.3c-5 7.2-10.2 14.3-15.4 21.4l0 0 0 0c-12.3 16.8-24.6 33.7-34.5 51.8c-5.9 10.8-9.6 22.5-11.8 34.5H226.4c2.6-18.7 7.9-38.6 18.3-57.5c11.5-20.9 26.9-42.1 39.8-59.8l0 0 0 0 0 0c4.7-6.4 9-12.4 12.7-17.7zM192 128c-26.5 0-48 21.5-48 48c0 8.8-7.2 16-16 16s-16-7.200-16-16c0-44.2 35.8-80 80-80c8.8 0 16 7.2 16 16s-7.2 16-16 16zm0 384c-44.2 0-80-35.8-80-80V416H272v16c0 44.2-35.8 80-80 80z"),
  // warning: Font Awesome "triangle-exclamation"
  (rgb("#EB9113"), "0 0 512 512", "M256 32c14.2 0 27.3 7.5 34.5 19.8l216 368c7.3 12.4 7.3 27.7 .2 40.1S486.3 480 472 480H40c-14.3 0-27.6-7.7-34.7-20.1s-7-27.8 .2-40.1l216-368C228.7 39.5 241.8 32 256 32zm0 128c-13.3 0-24 10.7-24 24V296c0 13.3 10.7 24 24 24s24-10.7 24-24V184c0-13.3-10.7-24-24-24zm32 224a32 32 0 1 0 -64 0 32 32 0 1 0 64 0z"),
  // caution: Bootstrap Icons "cone-striped"
  (dlm-caution-color, "0 0 16 16", "M9.97 4.88l.953 3.811C10.158 8.878 9.14 9 8 9c-1.14 0-2.159-.122-2.923-.309L6.03 4.88C6.635 4.957 7.3 5 8 5s1.365-.043 1.97-.12zm-.245-.978L8.97.88C8.718-.13 7.282-.13 7.03.88L6.274 3.9C6.8 3.965 7.382 4 8 4c.618 0 1.2-.036 1.725-.098zm4.396 8.613a.5.5 0 0 1 .037.96l-6 2a.5.5 0 0 1-.316 0l-6-2a.5.5 0 0 1 .037-.96l2.391-.598.565-2.257c.862.212 1.964.339 3.165.339s2.303-.127 3.165-.339l.565 2.257 2.391.598z"),
)
#let dlm-callout-icon(color, fallback) = {
  if color == dlm-important-color { return dlm-stop-icon(color) }
  for (c, viewbox, path) in dlm-callout-icons {
    if c == color { return dlm-svg-icon(viewbox, path, color) }
  }
  text(color, weight: 900)[#fallback]
}

#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false,
    fill: white,
    stroke: (left: 3pt + icon_color, rest: 0.5pt + icon_color.lighten(55%)),
    width: 100%,
    radius: 4pt,
    clip: true,
    block(
      inset: 0pt,
      width: 100%,
      below: 0pt,
      block(
        fill: background_color.lighten(35%),
        width: 100%,
        inset: (x: 10pt, y: 7pt))[#set text(weight: 600, fill: dlm-navy, size: 0.95em); #if icon != none [#dlm-callout-icon(icon_color, icon) ]#title]) +
    if (body != []) {
      block(
        inset: 0pt,
        width: 100%,
        block(fill: body_background_color, width: 100%, inset: (x: 10pt, y: 8pt), body))
    }
  )
}

// Code blocks: Pandoc draws highlighted code as one inline raw() per token and
// ends each line with EndLine(), an inline raw newline. This replaces Pandoc's
// Skylighting() so the block uses the report's code style and marks itself, so
// the inline-code box (in dlm-report) leaves its tokens and line breaks alone.
#let dlm-in-code-block = state("dlm-in-code-block", false)
#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
  let blocks = []
  let lnum = start - 1
  for ln in sourcelines {
    if number {
      lnum = lnum + 1
      blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
    }
    blocks = blocks + ln + EndLine()
  }
  dlm-in-code-block.update(true)
  {
    // Comments and output stay upright (the highlighting theme italicizes them)
    show raw: set text(style: "normal")
    block(fill: dlm-code-bg, inset: 10pt, radius: 6pt, width: 100%, stroke: 0.75pt + dlm-mist, blocks)
  }
  dlm-in-code-block.update(false)
}

// Sub-figures: same as Quarto's helper but aware of chapter-encoded counters
#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)
        show figure: it => {
          let num = numbering(subcapnumbering, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num
            [ ]
            it.body
          })
          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }
        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// Cover ------------------------------------------------------------------------
#let dlm-cover(title: none, subtitle: none, report-type: none, authors: (), date: none, report-number: none, assets: none, fontsize: 12pt) = {
  page(
    margin: 0pt,
    header: none,
    footer: none,
    foreground: none,
    background: if assets != none { image(assets + "/cover.svg", width: 100%, height: 100%) },
  )[
    #place(left + top, dx: 0.95in, dy: 3.05in, block(width: 5.2in)[
      // No paragraph spacing and lines cut to the letter heights, so each v()
      // below is the visible gap
      #set par(spacing: 0pt, justify: false)
      #set text(top-edge: "cap-height", bottom-edge: "baseline")
      #if report-type != none [
        #text(size: 10.5pt, weight: 700, fill: dlm-blue, tracking: 0.14em)[#upper(report-type)]
        #v(12pt)
      ]
      #block[
        #set par(leading: 0.3em)
        #text(size: 34pt, weight: 700, fill: dlm-navy, tracking: -0.015em)[#title]
      ]
      #if subtitle != none [
        #v(36pt)
        #block[
          #set par(leading: 0.45em)
          #text(size: 16pt, weight: 500, fill: dlm-blue)[#subtitle]
        ]
      ]
      #v(18pt)
      #dlm-rule()
      #v(14pt)
      #set text(size: fontsize, fill: dlm-muted, top-edge: "cap-height", bottom-edge: "descender")
      #set par(leading: 0.5em)
      #if authors.len() > 0 [
        #text(fill: dlm-ink, weight: 500)[#if authors.len() == 2 { authors.map(a => a.name).join(" and ") } else { authors.map(a => a.name).join(", ", last: ", and ") }]
        #linebreak()
      ]
      #if date != none [#date]
      #if report-number != none [#h(6pt)|#h(6pt)#report-number]
    ])
    #if assets != none {
      place(right + bottom, dx: -0.55in, dy: -0.5in, image(assets + "/dlm-logo.png", width: 2.0in, alt: "Dynamic Learning Maps"))
    }
  ]
}

// Colophon (inside cover) ---------------------------------------------------------
#let dlm-colophon(citation: none, rights: none, copyright: none, publisher: none, funding: none, extra: none, fontsize: 12pt) = {
  page(header: none, footer: none, background: none, foreground: none)[
    #set text(size: fontsize, fill: dlm-ink)
    #set par(justify: false, leading: 0.6em, spacing: 0.9em)
    #align(bottom)[
      #if extra != none [#extra #v(12pt)]
      #if citation != none [
        #text(weight: 700, fill: dlm-navy)[Suggested citation]
        #v(4pt)
        #if rights != none [#par[#rights] #v(10pt)]
        #par(hanging-indent: 0.5in)[#citation]
        #v(10pt)
      ]
      #if funding != none [
        #funding
        #v(10pt)
      ]
      #box(fill: dlm-sky, width: 36pt, height: 3pt, radius: 1.5pt)
      #v(6pt)
      #if copyright != none [#copyright #linebreak()]
      #if publisher != none [#text(fill: dlm-muted)[#publisher]]
    ]
  ]
}

// Main template -------------------------------------------------------------------
#let dlm-report(
  title: none,
  subtitle: none,
  running-title: none,
  report-type: none,
  report-number: none,
  authors: (),
  date: none,
  citation: none,
  rights: none,
  copyright: none,
  publisher: none,
  funding: none,
  colophon-extra: none,
  keywords: (),
  lang: "en",
  region: "US",
  font: ("Atkinson Hyperlegible Next",),
  // Equations need an OpenType math font; Fira Math suits the sans-serif text
  mathfont: ("Fira Math",),
  codefont: ("Fira Code",),
  fontsize: 12pt,
  linestretch: 1,
  toc: true,
  toc-title: none,
  toc-depth: 2,
  lof: false,
  lot: false,
  cover: true,
  book: false,
  divider: false,
  assets: none,
  doc,
) = {
  dlm-assets-state.update(assets)
  dlm-text-font.update(font)
  // divider: true (every numbered chapter), false (none), or "after-first"
  // (every numbered chapter except chapter 1). {.divider} / {.no-divider}
  // on a heading overrides this.
  let divider-mode = if divider in (true, "true") { true } else if divider == "after-first" { "after-first" } else { false }
  set document(title: title, keywords: keywords)
  set document(author: authors.map(a => content-to-string(a.name))) if authors.len() > 0

  set text(lang: lang, region: region, size: fontsize, font: font, fill: dlm-ink, number-type: "lining")
  set par(justify: false, leading: 0.72em * linestretch, spacing: 1.15em)
  // Typst's built-in raw rule already shrinks code to 0.8em, and an em size set
  // here compounds with it. Dividing by 0.8 makes code 0.92 of the body size.
  show raw: set text(font: codefont, size: 0.85em / 0.8)
  show math.equation: set text(font: mathfont)
  show link: set text(fill: dlm-blue)
  show ref: set text(fill: dlm-blue)
  set strong(delta: 250)
  set list(marker: ([#text(fill: dlm-blue)[•]], [#text(fill: dlm-sky)[–]]), indent: 0.4em, body-indent: 0.6em)
  set enum(indent: 0.2em, body-indent: 0.6em)

  // Page geometry, running head, and the slide-style navy page tab ---------
  let margin-x = 1in
  let margin-top = 1.05in
  let margin-bottom = 1in
  // Running header and page number: slightly smaller than body text (10.5pt
  // with 12pt body text)
  let furniture-size = 0.875 * fontsize

  set page(
    paper: "us-letter",
    numbering: "1",
    margin: (x: margin-x, top: margin-top, bottom: margin-bottom),
    header: context {
      if dlm-in-front() or dlm-on-divider() { return }
      let page-no = here().page()
      if book {
        let openers = query(heading.where(level: 1)).filter(h => h.location().page() == page-no)
        if openers.len() > 0 { return }
      }
      let before = query(heading.where(level: 1).before(here()))
      let section = if before.len() > 0 { before.last() } else { none }
      set text(size: furniture-size, fill: dlm-muted)
      grid(
        columns: (1fr, auto),
        align: (left, right),
        text(weight: 600, fill: dlm-navy)[#if running-title != none { running-title } else { title }],
        if section != none {
          if section.numbering != none {
            text(fill: dlm-blue, weight: 600)[#numbering(section.numbering, ..counter(heading).at(section.location()).slice(0, 1))#h(6pt)]
          }
          section.body
        },
      )
      v(-4pt)
      line(length: 100%, stroke: 0.5pt + dlm-mist)
    },
    footer: none,
    // page furniture goes in the foreground so page-counter updates on the
    // same page are already applied when the number is drawn. Marked as an
    // artifact so it stays out of the PDF/UA tag tree (e.g., mid-table breaks)
    foreground: pdf.artifact(context {
      if page.numbering == none or dlm-on-divider() { return }
      let label = if dlm-in-front() { numbering("i", ..counter(page).get()) } else { numbering("1", ..counter(page).get()) }
      // navy tab, lower-left (echoes the slide-number tab)
      place(left + bottom, dx: -6pt, dy: 30pt,
        rotate(45deg, origin: center + horizon,
          rect(width: 70pt, height: 70pt, radius: 10pt, fill: dlm-navy)))
      place(left + bottom, dx: 0pt, dy: -12pt,
        box(width: 46pt, align(center, text(size: furniture-size, weight: 700, fill: white, label))))
      if assets != none {
        place(right + bottom, dx: -0.6in, dy: -0.38in, image(assets + "/dlm-logo.png", width: 0.95in, alt: "Dynamic Learning Maps"))
      }
    }),
  )

  // Headings ------------------------------------------------------------------
  set heading(numbering: dlm-heading-numbering)

  // Heading sizes and spacing scale with `fontsize`. Each number is the value
  // in points the design uses with 10.5pt body text, so the proportions hold
  // at any size. Page layout (in inches) stays fixed.
  let hsize(pt) = pt / 10.5 * fontsize

  show heading: set text(fill: dlm-navy, weight: 700)
  show heading: set par(justify: false, leading: 0.5em)
  show heading: set block(sticky: true)

  let opener-ornament() = if assets != none {
    pdf.artifact(place(top + left, dx: -margin-x, dy: -margin-top, image(assets + "/chapter.svg", width: 8.5in)))
  }

  show heading.where(level: 1): it => {
    // chapter-encoded float/equation counters (see numbering.typ)
    if book {
      context {
        let ch = counter(heading).at(it.location()).first()
        let base = if dlm-appendix-state.at(it.location()) != none { (500 + ch) * 1000 } else { ch * 1000 }
        if it.numbering == none { base = 0 }
        for k in dlm-float-kinds { counter(figure.where(kind: k)).update(base) }
        counter(math.equation).update(base)
      }
    }
    context {
    let loc = it.location()
    let n = counter(heading).at(loc).first()
    let in-appendix = dlm-appendix-state.at(loc) != none
    let numbered = it.numbering != none
    let default = numbered and (divider-mode == true or (divider-mode == "after-first" and (n > 1 or in-appendix)))
    let override = dlm-divider-override.at(loc)
    let wants-divider = if override != none { override } else { default }
    let blurb = dlm-divider-blurb.at(loc)

    if wants-divider {
      // Full-page divider: the heading lives here, the chapter text starts
      // on the next page.
      pagebreak(weak: true)
      [#metadata("divider") <dlm-divider>]
      if assets != none {
        pdf.artifact(place(top + left, dx: -margin-x, dy: -margin-top, image(assets + "/divider.svg", width: 8.5in, height: 11in)))
      }
      place(left + top, dy: 3.2in, block(width: 4.5in, {
        set par(spacing: 0pt, leading: 0.42em, justify: false)
        if numbered {
          let label = if in-appendix { "Appendix" } else if book { "Chapter" } else { "Section" }
          block(below: hsize(6), text(size: hsize(10.5), weight: 700, fill: dlm-blue, tracking: 0.16em)[#upper(label)])
          block(below: hsize(14), text(size: hsize(64), weight: 800, fill: dlm-sky, tracking: -0.02em, top-edge: "cap-height", bottom-edge: "baseline")[#numbering(it.numbering, ..counter(heading).at(loc))])
        }
        block(below: hsize(18), text(size: hsize(30), weight: 700, fill: dlm-navy, tracking: -0.015em, it.body))
        if blurb != none {
          block(below: hsize(18), width: 4.2in, {
            set par(leading: 0.6em)
            text(size: hsize(13), style: "italic", fill: dlm-muted, blurb)
          })
        }
        dlm-rule()
      }))
      pagebreak()
    } else if book {
      pagebreak(weak: true)
      opener-ornament()
      v(0.65in)
      if it.numbering != none {
        context {
          let label = if dlm-appendix-state.get() != none { "Appendix" } else { "Chapter" }
          text(size: hsize(10), weight: 700, fill: dlm-blue, tracking: 0.14em)[#upper(label) #counter(heading).display(it.numbering)]
        }
        v(hsize(8))
      }
      block(text(size: hsize(26), tracking: -0.01em, it.body))
      v(hsize(4))
      dlm-rule()
      v(hsize(5))
    } else {
      block(above: hsize(30), below: hsize(12))[
        #set text(size: hsize(19), tracking: -0.01em)
        #if it.numbering != none [#counter(heading).display(it.numbering)#h(hsize(12))]#it.body
        #v(hsize(-2))
        #dlm-rule(width: 40pt)
      ]
    }
    }
  }

  show heading.where(level: 2): it => {
    block(above: hsize(24), below: hsize(10))[
      #set text(size: if book { hsize(15) } else { hsize(14) })
      #if it.numbering != none [#counter(heading).display(it.numbering)#h(hsize(10))]#it.body
    ]
  }
  show heading.where(level: 3): it => {
    block(above: hsize(18), below: hsize(8))[
      #set text(size: hsize(12), weight: 650)
      #if it.numbering != none [#counter(heading).display(it.numbering)#h(hsize(8))]#it.body
    ]
  }
  show heading.where(level: 4): it => block(above: hsize(12), below: hsize(6), text(size: hsize(10.5), weight: 650, fill: dlm-blue)[
    #if it.numbering != none [#counter(heading).display(it.numbering)#h(hsize(6))]#it.body
  ])
  show heading.where(level: 5): it => block(above: hsize(10), below: hsize(6), text(size: hsize(10.5), weight: 600, style: "italic", it.body))

  // Figures and tables ----------------------------------------------------------
  set figure(numbering: dlm-float-number, gap: 10pt)
  set math.equation(numbering: equation-numbering)
  show figure: set block(above: 18pt, below: 18pt)
  show figure: set align(left)
  show figure.where(kind: "quarto-float-tbl"): set figure.caption(position: top)
  // Captions, tables, and the reference list use the body text size
  show figure.caption: it => {
    set par(justify: false, leading: 0.6em)
    block(width: 100%)[
      #text(weight: 700, fill: dlm-navy)[#it.supplement #context it.counter.display(it.numbering)]#h(8pt)#it.body
    ]
  }

  set table(
    inset: (x: 7pt, y: 5pt),
    stroke: none,
    fill: (x, y) => if y == 0 { dlm-mist } else if calc.even(y) { dlm-tint },
  )
  set table.hline(stroke: 0.8pt + dlm-navy)
  show table.cell.where(y: 0): set text(weight: 650, fill: dlm-navy)
  show table: set text(number-type: "lining", number-width: "tabular")
  show table: set par(justify: false, leading: 0.55em)
  // Bottom rule: placed after the table so it's drawn on top of the cell
  // fills. As a block stroke it was drawn underneath them, so a shaded last
  // row covered half of it and the rule looked lighter on some tables.
  // The rule is as wide as the table itself, which can be narrower than the page.
  // The width is also recorded for the table's notes (dlm-table-notes()),
  // which follow directly below (hence no spacing below the table; tables
  // sit at the end of their figure, so nothing else follows inside it).
  show table: it => block(below: 0pt, layout(size => {
    let w = measure(it, width: size.width).width
    dlm-table-width.update(w)
    block({
      it
      place(bottom + left, line(length: w, stroke: 0.8pt + dlm-navy))
    })
  }))
  // Footnote marks in tables (e.g., gt's tab_footnote()): Typst's default
  // superscript (0.6em) makes symbols like * and † nearly unreadable, and gt
  // sets the marks in italics, which slants them away from the text. Raise
  // them at full size and upright instead. `typographic: false` keeps the
  // font's own (smaller) superscript glyphs from overriding the size.
  // Daggers sit on the baseline like letters, so they're raised a little; the
  // font already draws the asterisk high, so it stays on the baseline (the
  // website does the same in dlm.scss).
  show table: set super(typographic: false, size: 1em, baseline: -0.3em)
  show table: it => {
    show super: set text(style: "normal")
    show super: s => if s.body == [\*] { s.body } else { s }
    it
  }

  // Code ---------------------------------------------------------------------------
  // Code blocks match the website: plain background, thin border, rounded corners
  show raw.where(block: true): set block(fill: dlm-code-bg, inset: 10pt, radius: 6pt, width: 100%, stroke: 0.75pt + dlm-mist)
  // Inline code gets a tinted box; tokens inside highlighted code blocks don't
  show raw.where(block: false): it => context {
    if dlm-in-code-block.get() { it } else { box(fill: dlm-tint, inset: (x: 3pt), outset: (y: 2.5pt), radius: 2pt, it) }
  }

  // Quotes and footnotes ----------------------------------------------------
  set quote(block: true)
  show quote.where(block: true): it => block(inset: (left: 14pt, y: 4pt), stroke: (left: 3pt + dlm-sky), text(fill: dlm-muted, it.body))
  set footnote.entry(separator: line(length: 25%, stroke: 0.5pt + dlm-mist), indent: 0pt)
  show footnote.entry: set text(size: 8.5pt)

  // Outline styling -------------------------------------------------------------------
  show outline: it => {
    dlm-in-outline.update(true)
    it
    dlm-in-outline.update(false)
  }
  set outline.entry(fill: box(width: 1fr, repeat(text(fill: dlm-mist.darken(25%))[.], gap: 0.25em)))
  // Entries use the body text size (fontsize)
  show outline.entry.where(level: 1): it => {
    v(hsize(9), weak: true)
    if it.element.func() == figure {
      // Lists of tables and figures: bold number, regular title
      link(it.element.location(), it.indented(text(weight: 650, fill: dlm-navy, it.prefix()), text(fill: dlm-ink, it.inner())))
    } else {
      set text(weight: 650, fill: dlm-navy)
      it
    }
  }

  // Front matter -------------------------------------------------------------------------
  if cover and title != none {
    dlm-cover(title: title, subtitle: subtitle, report-type: report-type, authors: authors, date: date, report-number: report-number, assets: assets, fontsize: fontsize)
    dlm-colophon(citation: citation, rights: rights, copyright: copyright, publisher: publisher, funding: funding, extra: colophon-extra, fontsize: fontsize)
  }

  let front-heading(t) = {
    pagebreak(weak: true)
    opener-ornament()
    v(0.65in)
    block(text(size: hsize(26), weight: 700, fill: dlm-navy, tracking: -0.01em, t))
    v(hsize(4))
    dlm-rule()
    v(hsize(22))
  }

  let has-front = toc or lot or lof
  if has-front {
    counter(page).update(1)
    if toc {
      front-heading(if toc-title != none { toc-title } else { [Contents] })
      outline(title: none, depth: toc-depth, indent: auto)
    }
    if lot {
      front-heading[List of Tables]
      outline(title: none, target: figure.where(kind: "quarto-float-tbl"))
    }
    if lof {
      front-heading[List of Figures]
      outline(title: none, target: figure.where(kind: "quarto-float-fig"))
    }
    pagebreak(weak: true)
  }

  [#metadata("body") <dlm-body-start>]
  counter(page).update(1)

  doc
}
