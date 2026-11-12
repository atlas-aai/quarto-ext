--[[
dlm-report.lua
Shared metadata handling for the DLM report formats.

  * fills in DLM/ATLAS defaults under the `dlm:` metadata key
  * HTML: attaches the font + ornament dependency and flags the book home page
    so the title-block partial renders the cover hero
  * Typst: tells the template where the extension's image assets live,
    relative to the generated .typ file
]]

local ATLAS = "Accessible Teaching, Learning, and Assessment Systems (ATLAS), University of Kansas"
local RIGHTS = "**All rights reserved.** Any or all portions of this document may be reproduced and distributed without prior permission provided the source is cited as:"

local function str(x)
  if x == nil then return nil end
  return pandoc.utils.stringify(x)
end

local function basename(path)
  return path and path:match("([^/\\]+)$") or nil
end

local function strip_ext(path)
  return path and path:gsub("%.[^%.]+$", "") or nil
end

local function ensure_dlm(meta)
  local dlm = meta.dlm
  if dlm == nil or pandoc.utils.type(dlm) ~= "table" then
    dlm = {}
  end
  if dlm.publisher == nil then
    dlm.publisher = pandoc.Inlines(ATLAS)
  end
  if dlm.copyright == nil then
    dlm.copyright = pandoc.Inlines("Copyright © " .. os.date("%Y"))
  end
  if dlm.cover == nil then
    dlm.cover = true
  end
  if dlm["report-type"] == nil then
    dlm["report-type"] = pandoc.Inlines("Technical Report")
  end
  -- Shown above the suggested citation; `rights: false` drops it
  if dlm.rights == nil then
    dlm.rights = pandoc.utils.blocks_to_inlines(pandoc.read(RIGHTS, "markdown").blocks)
  end
  meta.dlm = dlm
  return meta
end

-- Is the current document the home page of a website or book?
local function is_home()
  local input = quarto.doc.input_file
  if input == nil then return false end
  local name = basename(input)
  if name ~= "index.qmd" and name ~= "index.md" and name ~= "index.ipynb" then
    return false
  end
  local proj = quarto.project and quarto.project.directory
  if proj == nil then return true end
  local dir = pandoc.path.directory(input)
  return pandoc.path.normalize(dir) == pandoc.path.normalize(proj)
end

local function pdf_name(meta)
  local dlm = meta.dlm or {}
  if dlm["pdf-file"] ~= nil then return str(dlm["pdf-file"]) end
  local book = meta.book
  if book ~= nil and book["output-file"] ~= nil then
    return strip_ext(str(book["output-file"])) .. ".pdf"
  end
  if meta.title ~= nil then
    return str(meta.title) .. ".pdf"
  end
  return nil
end

local function to_typst(inlines)
  local out = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "typst")
  return (out:gsub("%s+$", ""))
end

-- Level-1 heading extras (adapted from wjt-report):
--   # Modeling {.divider}        force a PDF divider page for this heading
--   # Results {.no-divider}      suppress the divider for this heading
--   # Modeling {blurb="..."}     italic blurb under the title on the divider page
--                               (shown as a lead paragraph on the website)
-- The override and blurb are reset at every level-1 heading so they never
-- leak into the next chapter.
function Header(el)
  if el.level ~= 1 then return nil end

  local override = "none"
  if el.classes:includes("divider") then
    override = "true"
  elseif el.classes:includes("no-divider") then
    override = "false"
  end
  el.classes = el.classes:filter(function(c) return c ~= "divider" and c ~= "no-divider" end)

  local blurb = el.attributes["blurb"]
  el.attributes["blurb"] = nil
  local blurb_inlines = nil
  if blurb ~= nil and blurb ~= "" then
    blurb_inlines = pandoc.utils.blocks_to_inlines(pandoc.read(blurb, "markdown").blocks)
  end

  if quarto.doc.is_format("typst") then
    local blurb_typst = blurb_inlines and ("[" .. to_typst(blurb_inlines) .. "]") or "none"
    return {
      pandoc.RawBlock("typst", "#dlm-divider-override.update(" .. override .. ")"),
      pandoc.RawBlock("typst", "#dlm-divider-blurb.update(" .. blurb_typst .. ")"),
      el,
    }
  end

  if quarto.doc.is_format("html") and blurb_inlines ~= nil then
    return { el, pandoc.Div({ pandoc.Para(blurb_inlines) }, pandoc.Attr("", { "dlm-blurb" })) }
  end

  return el
end

-- Typst: citeproc fills the `::: {#refs}` div with the reference list (from
-- the document's `csl`, e.g. APA). Style it as a reference list with the
-- 0.5in hanging indent APA requires.
--
-- Typst: tables stay on one page with their caption. A table chunk with
-- `#| classes: breakable` (or a `::: {.breakable}` div) may split across pages
-- instead, repeating its header row, like kableExtra's `longtable`.
function Div(el)
  if not quarto.doc.is_format("typst") then return nil end
  if el.identifier == "refs" then
    return {
      pandoc.RawBlock("typst", "#[#set par(hanging-indent: 0.5in, spacing: 0.9em, leading: 0.6em)"),
      el,
      pandoc.RawBlock("typst", "]"),
    }
  end
  if el.classes:includes("breakable") then
    return {
      pandoc.RawBlock("typst", "#[#show figure: set block(breakable: true)"),
      el,
      pandoc.RawBlock("typst", "]"),
    }
  end
  -- `::: {.center}` centers its text (the website does this in dlm.scss)
  if el.classes:includes("center") then
    return {
      pandoc.RawBlock("typst", "#align(center)["),
      el,
      pandoc.RawBlock("typst", "]"),
    }
  end
  -- `::: {.hanging}` gives each paragraph a 0.5in hanging indent, as in APA
  -- references (the website does this in dlm.scss)
  if el.classes:includes("hanging") then
    return {
      pandoc.RawBlock("typst", "#[#set par(hanging-indent: 0.5in)"),
      el,
      pandoc.RawBlock("typst", "]"),
    }
  end
end

-- Book chapters: Quarto turns the chapter's H1 into the page title before
-- filters run, so its attributes are gone. Read the blurb from the source line.
local function chapter_blurb_from_source()
  local input = quarto.doc.input_file
  if input == nil then return nil end
  local f = io.open(input, "r")
  if f == nil then return nil end
  local in_yaml, in_code = false, false
  local first = true
  for line in f:lines() do
    if first and line:match("^%-%-%-%s*$") then
      in_yaml = true
    elseif in_yaml then
      if line:match("^%-%-%-%s*$") or line:match("^%.%.%.%s*$") then in_yaml = false end
    elseif line:match("^```") then
      in_code = not in_code
    elseif not in_code and line:match("^#%s") then
      f:close()
      return line:match('blurb%s*=%s*"(.-)"') or line:match("blurb%s*=%s*'(.-)'")
    end
    first = false
  end
  f:close()
  return nil
end

function Meta(meta)
  meta = ensure_dlm(meta)

  if quarto.doc.is_format("html") and meta.book ~= nil and meta["dlm-blurb"] == nil then
    local blurb = chapter_blurb_from_source()
    if blurb ~= nil and blurb ~= "" then
      meta["dlm-blurb"] = pandoc.MetaInlines(pandoc.utils.blocks_to_inlines(pandoc.read(blurb, "markdown").blocks))
    end
  end

  if quarto.doc.is_format("html") then
    quarto.doc.add_html_dependency({
      name = "dlm-report",
      version = "0.1.0",
      stylesheets = { "html/dlm-assets.css" },
      scripts = { { path = "html/dlm.js", afterBody = true } },
      resources = {
        "fonts/woff2/atkinson-hyperlegible-next-wght-normal.woff2",
        "fonts/woff2/atkinson-hyperlegible-next-wght-italic.woff2",
        "fonts/woff2/fira-code-wght-normal.woff2",
        "assets/dlm-logo.png",
        "assets/dlm-logo-white.png",
        "assets/hero-left.svg",
        "assets/hero-right.svg",
      },
    })

    if is_home() and meta["dlm-cover"] == nil then
      meta["dlm-cover"] = true
    end
    if meta["dlm-cover"] then
      local pdf = pdf_name(meta)
      local show_pdf = meta.dlm["show-pdf-button"]
      if pdf ~= nil and (show_pdf == nil or show_pdf == true) then
        meta["dlm-pdf"] = pandoc.MetaString(pdf)
      end
    end
  end

  if quarto.doc.is_format("typst") then
    local assets = quarto.utils.resolve_path("assets")
    local base = pandoc.path.directory(quarto.doc.input_file or ".")
    local rel = pandoc.path.make_relative(assets, base)
    -- Typst always wants forward slashes
    rel = rel:gsub("\\", "/")
    meta["dlm-assets"] = pandoc.MetaInlines({ pandoc.RawInline("typst", rel) })
    if meta.book ~= nil then
      meta["dlm-book"] = true
    end
  end

  return meta
end
