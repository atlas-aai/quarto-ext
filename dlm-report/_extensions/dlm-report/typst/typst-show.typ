
#show: doc => dlm-report(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(dlm.running-title)$
  running-title: [$dlm.running-title$],
$endif$
$if(dlm.report-type)$
  report-type: [$dlm.report-type$],
$endif$
$if(dlm.report-number)$
  report-number: [$dlm.report-number$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
      email: [$it.email$] ),
$endif$
$endfor$
  ),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(dlm.rights)$
  rights: [$dlm.rights$],
$endif$
$if(dlm.citation)$
  citation: [$dlm.citation$],
$endif$
$if(dlm.copyright)$
  copyright: [$dlm.copyright$],
$endif$
$if(dlm.publisher)$
  publisher: [$dlm.publisher$],
$endif$
$if(dlm.funding)$
  funding: [$dlm.funding$],
$endif$
$if(dlm.colophon)$
  colophon-extra: [$dlm.colophon$],
$endif$
$if(keywords)$
  keywords: ($for(keywords)$"$keywords$",$endfor$),
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(mainfont)$
  font: ("$mainfont$", "Atkinson Hyperlegible Next"),
$endif$
$if(mathfont)$
  mathfont: ($for(mathfont)$"$mathfont$",$endfor$ "Fira Math"),
$endif$
$if(codefont)$
  codefont: ($for(codefont)$"$codefont$",$endfor$ "Fira Code"),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
$if(linestretch)$
  linestretch: $linestretch$,
$endif$
  toc: $if(toc)$true$else$false$endif$,
$if(toc-title)$
  toc-title: [$toc-title$],
$endif$
$if(toc-depth)$
  toc-depth: $toc-depth$,
$endif$
  lof: $if(lof)$true$else$false$endif$,
  lot: $if(lot)$true$else$false$endif$,
  cover: $if(dlm.cover)$true$else$false$endif$,
  book: $if(dlm-book)$true$else$false$endif$,
  divider: $if(dlm.divider)$"$dlm.divider$"$else$false$endif$,
$if(dlm-assets)$
  assets: "$dlm-assets$",
$endif$
  doc,
)
