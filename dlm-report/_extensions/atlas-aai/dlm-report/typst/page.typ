// Page geometry, running heads, and page furniture are set inside dlm-report()
// (see typst-template.typ). This partial intentionally sets only the paper size.
#set page(paper: $if(papersize)$"$papersize$"$else$"us-letter"$endif$)
