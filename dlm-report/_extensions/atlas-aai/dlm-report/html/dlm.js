// DLM report: small progressive enhancements for the website format.

// Equations use MathJax's Fira font, matching Fira Math in the PDF. Text in
// equations, including equation numbers (\tag), uses the page font. MathJax
// loads with `defer`, so this runs first; a document's own MathJax config wins.
window.MathJax = window.MathJax || {};
window.MathJax.output = Object.assign(
  { font: "mathjax-fira", mtextInheritFont: true },
  window.MathJax.output
);

document.addEventListener("DOMContentLoaded", () => {
  // Label chapter titles "Chapter 3" or "Appendix B"
  document.querySelectorAll("#title-block-header h1.title .chapter-number").forEach((el) => {
    const n = el.textContent.trim();
    el.setAttribute("data-dlm-label", /^[A-Z]+$/.test(n) ? "Appendix" : "Chapter");
  });

  // Accessibility (axe): give Quarto's navigation landmarks distinct names, and
  // drop the invalid role="menu" from the navbar's collapse button
  const navLabels = {
    "#quarto-header nav.navbar": "Site",
    "nav.quarto-secondary-nav": "Mobile",
    "nav#quarto-sidebar": "Chapters",
    "nav.page-navigation": "Previous and next chapter",
  };
  Object.entries(navLabels).forEach(([selector, label]) => {
    document.querySelectorAll(`${selector}:not([aria-label]):not([aria-labelledby])`)
      .forEach((nav) => nav.setAttribute("aria-label", label));
  });
  document.querySelectorAll(".navbar-toggler[role='menu']").forEach((el) => el.removeAttribute("role"));
  // Collapse toggles (e.g., the sidebar's "Appendices") are buttons, not landmarks
  document.querySelectorAll("a[role='navigation'][data-bs-toggle]").forEach((el) => el.setAttribute("role", "button"));

  // Tables and code blocks that scroll sideways must be reachable by keyboard
  const scrollers = document.querySelectorAll(
    ".cell-output-display:has(> table), .cell-output-display:has(> .table), .quarto-float:has(table), " +
    "div:has(> table.gt_table), div.sourceCode"
  );
  const updateScrollers = () => scrollers.forEach((el) => {
    if (el.scrollWidth > el.clientWidth) {
      el.setAttribute("tabindex", "0");
    } else {
      el.removeAttribute("tabindex");
    }
  });
  updateScrollers();
  window.addEventListener("resize", updateScrollers);

  // Emphasize the "Table 2.1" / "Figure 3.4" label in captions
  const capSelector = "figcaption, caption, .figure-caption, .quarto-float-caption";
  document.querySelectorAll(capSelector).forEach((cap) => {
    if (cap.querySelector(".dlm-cap-label")) return;
    const walker = document.createTreeWalker(cap, NodeFilter.SHOW_TEXT);
    const node = walker.nextNode();
    if (!node) return;
    const m = node.textContent.match(/^(\s*)((?:Table|Figure|Listing) ?\s?[A-Z]?[\d.]+[a-z]?)(:\s*)?/);
    if (!m) return;
    const label = document.createElement("span");
    label.className = "dlm-cap-label";
    label.textContent = m[2];
    const rest = document.createTextNode(node.textContent.slice(m[0].length));
    node.parentNode.insertBefore(label, node);
    node.parentNode.insertBefore(rest, node);
    node.parentNode.removeChild(node);
  });

  // Cover: point "Start reading" at the first chapter
  const start = document.querySelector(".dlm-start-reading");
  const next = document.querySelector(".nav-page-next a");
  if (start && next) {
    start.href = next.getAttribute("href");
    start.hidden = false;
  }
});
