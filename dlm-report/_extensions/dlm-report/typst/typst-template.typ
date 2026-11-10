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
  if n.len() <= 3 { numbering("1.1", ..n) }
}
#let dlm-appendix-heading-numbering(..nums) = {
  let n = nums.pos()
  if n.len() <= 3 { numbering("A.1", ..n) }
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
        inset: (x: 10pt, y: 7pt))[#set text(weight: 600, fill: dlm-navy, size: 0.95em); #if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
    if (body != []) {
      block(
        inset: 0pt,
        width: 100%,
        block(fill: body_background_color, width: 100%, inset: (x: 10pt, y: 8pt), body))
    }
  )
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
#let dlm-cover(title: none, subtitle: none, report-type: none, authors: (), date: none, report-number: none, assets: none) = {
  page(
    margin: 0pt,
    header: none,
    footer: none,
    foreground: none,
    background: if assets != none { image(assets + "/cover.svg", width: 100%, height: 100%) },
  )[
    #place(left + top, dx: 0.95in, dy: 3.05in, block(width: 5.2in)[
      #if report-type != none [
        #text(size: 10.5pt, weight: 700, fill: dlm-blue, tracking: 0.14em)[#upper(report-type)]
        #v(10pt)
      ]
      #set par(leading: 0.42em, justify: false)
      #text(size: 34pt, weight: 700, fill: dlm-navy, tracking: -0.015em)[#title]
      #if subtitle != none [
        #v(12pt)
        #set par(leading: 0.55em)
        #text(size: 16pt, weight: 500, fill: dlm-blue)[#subtitle]
      ]
      #v(22pt)
      #dlm-rule()
      #v(14pt)
      #set text(size: 10.5pt, fill: dlm-muted)
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
#let dlm-colophon(citation: none, copyright: none, publisher: none, funding: none, extra: none) = {
  page(header: none, footer: none, background: none, foreground: none)[
    #set text(size: 9pt, fill: dlm-ink)
    #set par(justify: false, leading: 0.6em, spacing: 0.9em)
    #align(bottom)[
      #if extra != none [#extra #v(12pt)]
      #if citation != none [
        #text(weight: 700, fill: dlm-navy, size: 9.5pt)[Suggested citation]
        #v(4pt)
        #block(inset: (left: 1.5em))[#par(hanging-indent: 1.5em)[#citation]]
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
  codefont: ("JetBrains Mono",),
  fontsize: 10.5pt,
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
  show raw: set text(font: codefont, size: 0.88em)
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
      set text(size: 8.5pt, fill: dlm-muted)
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
        box(width: 46pt, align(center, text(size: 8.5pt, weight: 700, fill: white, label))))
      if assets != none {
        place(right + bottom, dx: -0.6in, dy: -0.38in, image(assets + "/dlm-logo.png", width: 0.95in, alt: "Dynamic Learning Maps"))
      }
    }),
  )

  // Headings ------------------------------------------------------------------
  set heading(numbering: dlm-heading-numbering)

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
          block(below: 6pt, text(size: 10.5pt, weight: 700, fill: dlm-blue, tracking: 0.16em)[#upper(label)])
          block(below: 14pt, text(size: 64pt, weight: 800, fill: dlm-sky, tracking: -0.02em, top-edge: "cap-height", bottom-edge: "baseline")[#numbering(it.numbering, ..counter(heading).at(loc))])
        }
        block(below: 18pt, text(size: 30pt, weight: 700, fill: dlm-navy, tracking: -0.015em, it.body))
        if blurb != none {
          block(below: 18pt, width: 4.2in, {
            set par(leading: 0.6em)
            text(size: 13pt, style: "italic", fill: dlm-muted, blurb)
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
          text(size: 10pt, weight: 700, fill: dlm-blue, tracking: 0.14em)[#upper(label) #counter(heading).display(it.numbering)]
        }
        v(8pt)
      }
      block(text(size: 26pt, tracking: -0.01em, it.body))
      v(4pt)
      dlm-rule()
      v(22pt)
    } else {
      block(above: 30pt, below: 12pt)[
        #set text(size: 19pt, tracking: -0.01em)
        #if it.numbering != none [#counter(heading).display(it.numbering)#h(12pt)]#it.body
        #v(-2pt)
        #dlm-rule(width: 40pt)
      ]
    }
    }
  }

  show heading.where(level: 2): it => {
    block(above: 24pt, below: 10pt)[
      #set text(size: if book { 15pt } else { 14pt })
      #if it.numbering != none [#counter(heading).display(it.numbering)#h(10pt)]#it.body
    ]
  }
  show heading.where(level: 3): it => {
    block(above: 18pt, below: 8pt)[
      #set text(size: 12pt, weight: 650)
      #if it.numbering != none [#counter(heading).display(it.numbering)#h(8pt)]#it.body
    ]
  }
  show heading.where(level: 4): it => block(above: 12pt, below: 6pt, text(size: 10.5pt, weight: 650, fill: dlm-blue, it.body))
  show heading.where(level: 5): it => block(above: 10pt, below: 6pt, text(size: 10.5pt, weight: 600, style: "italic", it.body))

  // Figures and tables ----------------------------------------------------------
  set figure(numbering: dlm-float-number, gap: 10pt)
  set math.equation(numbering: equation-numbering)
  show figure: set block(above: 18pt, below: 18pt)
  show figure: set align(left)
  show figure.where(kind: "quarto-float-tbl"): set block(breakable: true)
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
  show table: it => block(stroke: (bottom: 0.8pt + dlm-navy), it)

  // Code ---------------------------------------------------------------------------
  show raw.where(block: true): set block(fill: dlm-tint, inset: 10pt, radius: 4pt, width: 100%, stroke: (left: 2pt + dlm-sky))
  show raw.where(block: false): box.with(fill: dlm-tint, inset: (x: 3pt), outset: (y: 2.5pt), radius: 2pt)

  // Quotes and footnotes ----------------------------------------------------
  set quote(block: true)
  show quote.where(block: true): it => block(inset: (left: 14pt, y: 4pt), stroke: (left: 3pt + dlm-sky), text(fill: dlm-muted, it.body))
  set footnote.entry(separator: line(length: 25%, stroke: 0.5pt + dlm-mist), indent: 0pt)
  show footnote.entry: set text(size: 8.5pt)

  // Outline styling -------------------------------------------------------------------
  set outline.entry(fill: box(width: 1fr, repeat(text(fill: dlm-mist.darken(25%))[.], gap: 0.25em)))
  show outline.entry: set text(size: 10pt)
  show outline.entry.where(level: 1): it => {
    v(9pt, weak: true)
    set text(weight: 650, fill: dlm-navy)
    it
  }

  // Front matter -------------------------------------------------------------------------
  if cover and title != none {
    dlm-cover(title: title, subtitle: subtitle, report-type: report-type, authors: authors, date: date, report-number: report-number, assets: assets)
    dlm-colophon(citation: citation, copyright: copyright, publisher: publisher, funding: funding, extra: colophon-extra)
  }

  let front-heading(t) = {
    pagebreak(weak: true)
    opener-ornament()
    v(0.65in)
    block(text(size: 26pt, weight: 700, fill: dlm-navy, tracking: -0.01em, t))
    v(4pt)
    dlm-rule()
    v(22pt)
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
