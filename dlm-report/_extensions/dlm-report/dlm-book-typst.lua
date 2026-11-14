--[[
dlm-book-typst.lua
Part and appendix handling for Typst *books* rendered with the DLM format.
Quarto marks every chapter of a book with file metadata; level-1 headings of
parts and appendices are swapped for calls into the DLM Typst template.

Also gives every equation alt text (its TeX source), which PDF/UA-1 requires,
and drops gt's default styling from gt tables so the template's table design
applies (styling added with gt::tab_style() is kept).

Short captions: a `fig-scap` or `tbl-scap` attribute on a figure or table
wraps the caption in the template's `dlm-flex-caption()`, so the lists of
figures and tables show the short caption instead of the full one.
]]

local function is_typst_book()
  local file_state = quarto.doc.file_metadata()
  return quarto.doc.is_format("typst") and file_state ~= nil and file_state.file ~= nil
end

local header_filter = {
  Header = function(el)
    if not is_typst_book() then return nil end
    local file = quarto.doc.file_metadata().file
    local item_type = file.bookItemType
    if el.level ~= 1 or item_type == nil then return nil end

    if item_type == "part" then
      return pandoc.RawBlock("typst", "#dlm-part[" .. pandoc.utils.stringify(el.content) .. "]")
    end

    if item_type == "appendix" then
      if file.bookItemNumber == 1 or file.bookItemNumber == nil then
        local language = quarto.doc.language
        local title = (language and language["section-title-appendices"]) or "Appendices"
        local start = pandoc.RawBlock("typst", '#show: dlm-appendices.with("' .. title .. '")')
        if el.classes:includes("unnumbered") then
          -- synthetic "Appendices" divider emitted by Quarto
          return { start, pandoc.RawBlock("typst", "#dlm-part[" .. title .. "]") }
        end
        return { start, el }
      end
    end
    return nil
  end,
}

-- PDF/UA-1: every equation needs alt text. Use the TeX source.
local function typst_string(s)
  s = s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local math_alt_filter = {
  Inlines = function(inlines)
    if not quarto.doc.is_format("typst") then return nil end
    local out = pandoc.Inlines({})
    for i, el in ipairs(inlines) do
      if el.t == "Math" then
        local alt = typst_string(el.text)
        local prev = out[#out]
        -- numbered equations: Quarto wraps the math in a raw `#math.equation(`
        if prev and prev.t == "RawInline" and prev.format == "typst"
            and prev.text:match("^#math%.equation%(") then
          prev.text = prev.text:gsub("^#math%.equation%(", "#math.equation(alt: " .. alt .. ", ", 1)
          out:insert(el)
        else
          out:insert(pandoc.RawInline("typst", "#[#set math.equation(alt: " .. alt .. ");"))
          out:insert(el)
          out:insert(pandoc.RawInline("typst", "]"))
        end
      else
        out:insert(el)
      end
    end
    return out
  end,
}

-- gt tables: gt inlines its default CSS (Roboto at 12pt, white fills, gray
-- rules) into every table and cell, and Quarto turns that CSS into Typst
-- styling that overrides the template. Keep only the declarations an author
-- added with tab_style() (colors, fills, weight, italics) and drop gt's
-- defaults, layout, and borders so the template's table design applies.
local gt_drop_props = {
  ["font-family"] = true, ["display"] = true, ["border-collapse"] = true,
  ["line-height"] = true, ["width"] = true, ["text-transform"] = true,
  ["vertical-align"] = true, ["font-variant-numeric"] = true,
}
local gt_default_values = {
  ["color"] = { "#333333" },
  ["background-color"] = { "#ffffff", "rgba(128, 128, 128, 0.05)" },
  ["font-size"] = { "16px", "100%" },
  ["font-weight"] = { "normal", "initial" },
  ["font-style"] = { "normal" },
}

-- Vertical rules: a left or right border from tab_style(cell_borders()) is
-- kept, while gt's own borders (gray or white, or style none) are dropped.
-- Horizontal rules always come from the template.
local gt_default_border_colors = { ["#d3d3d3"] = true, ["#a8a8a8"] = true, ["#ffffff"] = true }

local function author_border_sides(style)
  local sides = {}
  for _, side in ipairs({ "left", "right" }) do
    local s = style:match("border%-" .. side .. "%-style%s*:%s*([^;]+)")
    local c = style:match("border%-" .. side .. "%-color%s*:%s*([^;]+)")
    s = s and s:lower():gsub("%s+$", "")
    c = c and c:lower():gsub("%s+$", "")
    if s and s ~= "none" and s ~= "hidden" and c and not gt_default_border_colors[c] then
      sides[side] = true
    end
  end
  return sides
end

local function clean_gt_css(style)
  local kept = {}
  local sides = author_border_sides(style)
  for decl in style:gmatch("[^;]+") do
    local prop, value = decl:match("^%s*([%w%-]+)%s*:%s*(.-)%s*$")
    if prop then
      prop = prop:lower()
      local side = prop:match("^border%-(%a+)%-")
      local drop = gt_drop_props[prop]
        or prop:match("^%-") or prop:match("^margin") or prop:match("^padding")
        or (prop:match("^border") and not (side and sides[side]))
        or prop:match("^overflow")
      for _, v in ipairs(gt_default_values[prop] or {}) do
        if value:lower() == v then drop = true end
      end
      if not drop then table.insert(kept, prop .. ": " .. value) end
    end
  end
  return #kept > 0 and table.concat(kept, "; ") or nil
end

local function clean_gt_attrs(attrs)
  if attrs["style"] then attrs["style"] = clean_gt_css(attrs["style"]) end
  if attrs["bgcolor"] and attrs["bgcolor"]:lower() == "#ffffff" then attrs["bgcolor"] = nil end
  for key, _ in pairs(attrs) do
    if key:match("^typst:") then attrs[key] = nil end
  end
end

-- Quarto does not carry CSS `text-indent` into Typst, so an indent from
-- tab_style(cell_text(indent = ...)) (e.g., rows within row groups in
-- gt_atlas()) is lost. Pad the cell's contents instead, which also indents
-- wrapped lines.
local function indent_cell(cell)
  local style = cell.attributes["style"]
  if not style then return end
  local value, unit = style:match("text%-indent%s*:%s*([%d%.]+)%s*(%a+)")
  if not value then return end
  local pt = tonumber(value)
  if unit == "px" then pt = pt * 0.75
  elseif unit == "em" then pt = nil
  elseif unit ~= "pt" then return end
  local amount = pt and string.format("%.2fpt", pt) or (value .. "em")
  local contents = pandoc.Blocks({ pandoc.RawBlock("typst", "#pad(left: " .. amount .. ")[") })
  contents:extend(cell.contents)
  contents:insert(pandoc.RawBlock("typst", "]"))
  cell.contents = contents
end

-- Spanner labels from tab_spanner() arrive as a `gt_column_spanner` div in a
-- header cell. Set them with the template's dlm-spanner(), which rules the
-- label across only its columns (gt draws this rule with CSS borders, which
-- are dropped above).
local spanner_filter = {
  Div = function(div)
    if not div.classes:includes("gt_column_spanner") then return nil end
    local blocks = pandoc.Blocks({ pandoc.RawBlock("typst", "#dlm-spanner[") })
    blocks:extend(div.content)
    blocks:insert(pandoc.RawBlock("typst", "]"))
    return blocks
  end,
}

-- Line breaks: in a Quarto render, gt passes md() text (e.g., a column label
-- of md("Correlation<br>(95% CI)")) to Quarto as markdown, so `<br>` becomes
-- raw HTML, which Typst output drops. Make it a real line break.
local html_break_filter = {
  RawInline = function(el)
    if el.format:match("^html") and el.text:match("^%s*<[bB][rR]%s*/?>%s*$") then
      return pandoc.LineBreak()
    end
    return nil
  end,
}

-- Zebra striping counts body rows only, so it starts at the first body row
-- however many header rows a table has (the website's `tbody
-- tr:nth-child(even)` does the same): the 2nd, 4th, ... body rows are shaded.
-- The template's fill (by row number) only covers tables this filter never
-- sees. A fill from tab_style(cell_fill()) is kept.
local function stripe_body(el)
  local n = 0
  for _, body in ipairs(el.bodies) do
    for _, list in ipairs({ body.head, body.body }) do
      for _, row in ipairs(list) do
        n = n + 1
        local fill = (n % 2 == 0) and "dlm-tint" or "none"
        for _, cell in ipairs(row.cells) do
          local style = cell.attributes["style"] or ""
          if not cell.attributes["typst:fill"] and not style:match("background%-color") then
            cell.attributes["typst:fill"] = fill
          end
        end
      end
    end
  end
end

-- Pandoc's HTML reader gives some gt tables (e.g., with spanners or
-- footnotes) equal fixed column widths, which squeezes label columns in the
-- PDF and stretches the table to the full column on the website. Equal widths
-- that gt did not set (cols_width()) go back to auto widths.
local function reset_equal_widths(el)
  local widths, equal = {}, true
  for i, spec in ipairs(el.colspecs) do
    widths[i] = spec[2]
    if type(widths[i]) ~= "number" or math.abs(widths[i] - widths[1]) > 1e-6 then equal = false end
  end
  if equal and #widths > 1 then
    for i, spec in ipairs(el.colspecs) do el.colspecs[i] = { spec[1], nil } end
  end
end

local gt_table_filter = {
  Table = function(el)
    if quarto.doc.is_format("html") and el.classes:includes("gt_table") then
      reset_equal_widths(el)
      -- Notes wrap at the table's width instead of widening the table: the
      -- `dlm-table-note` wrapper is sized in dlm.scss so it adds no width
      for _, row in ipairs(el.foot.rows) do
        for _, cell in ipairs(row.cells) do
          cell.contents = pandoc.Blocks({ pandoc.Div(cell.contents, pandoc.Attr("", { "dlm-table-note" })) })
        end
      end
      return el
    end
    if not quarto.doc.is_format("typst") then return nil end
    if not el.classes:includes("gt_table") then
      stripe_body(el)
      return el
    end
    el = el:walk(html_break_filter)
    clean_gt_attrs(el.attributes)
    reset_equal_widths(el)
    local halign = {
      AlignLeft = "left", AlignCenter = "center", AlignRight = "right",
    }
    -- Body cells are centered vertically, as gt does on the website, so values
    -- line up with the middle of a label that wraps onto several lines. A
    -- cell_text(v_align = ...) from tab_style() still wins. Typst takes
    -- horizontal and vertical alignment together, so the cell's horizontal
    -- alignment moves into a `typst:align` attribute (also used for headers).
    local valign = { top = "top", middle = "horizon", bottom = "bottom" }
    -- (read before clean_gt_attrs(), which drops `vertical-align`, and set
    -- after it, since it also drops `typst:` attributes)
    local function cell_valign(cell, default)
      local v = (cell.attributes["style"] or ""):match("vertical%-align%s*:%s*(%a+)")
      return (v and valign[v:lower()]) or default
    end
    local function set_valign(cell, v)
      local h = halign[tostring(cell.alignment)]
      cell.attributes["typst:align"] = h and (h .. " + " .. v) or v
      if h then cell.alignment = pandoc.AlignDefault end
    end
    local function rows(list, vdefault)
      for _, row in ipairs(list) do
        clean_gt_attrs(row.attributes)
        for _, cell in ipairs(row.cells) do
          indent_cell(cell)
          local v = vdefault and cell_valign(cell, vdefault)
          clean_gt_attrs(cell.attributes)
          if v then set_valign(cell, v) end
        end
      end
    end
    for _, row in ipairs(el.head.rows) do
      for _, cell in ipairs(row.cells) do
        cell.contents = cell.contents:walk(spanner_filter)
      end
    end
    rows(el.head.rows)
    -- Header cells sit at the bottom of their row, so spanner rules line up
    -- when one spanner label wraps and others don't, and labels spanning
    -- several header rows (e.g., the stub head) sit beside the lowest row.
    -- Typst takes horizontal and vertical alignment together, so the cell's
    -- horizontal alignment moves into a `typst:align` attribute.
    for _, row in ipairs(el.head.rows) do
      for _, cell in ipairs(row.cells) do
        local h = halign[tostring(cell.alignment)] or "center"
        cell.attributes["typst:align"] = h .. " + bottom"
        cell.alignment = pandoc.AlignDefault
        -- The template styles only the first table row as a header; with
        -- spanners there are more header rows (e.g., n and % under each
        -- spanner), so style every header cell the same way here
        cell.attributes["typst:fill"] = "dlm-mist"
        local contents = pandoc.Blocks({
          pandoc.RawBlock("typst", "#[#set text(weight: 650, fill: dlm-navy)"),
        })
        contents:extend(cell.contents)
        contents:insert(pandoc.RawBlock("typst", "]"))
        cell.contents = contents
      end
    end
    for _, body in ipairs(el.bodies) do
      rows(body.head)
      rows(body.body, "horizon")
    end
    rows(el.foot.rows)
    stripe_body(el)
    -- Notes and footnotes (the table footer) move out of the table into the
    -- template's dlm-table-notes() right after it, which sets them at the
    -- table's own width. As footer cells, a long note made Typst widen the
    -- table to fit it.
    if #el.foot.rows == 0 then return el end
    -- notes take the table's font size (tab_options(table.font.size = ...)),
    -- which gt sets as a CSS font-size on the table
    local size = "1em"
    local fs = (el.attributes["style"] or ""):match("font%-size%s*:%s*([^;]+)")
    if fs then
      local n, unit = fs:match("^%s*([%d%.]+)%s*(%S*)")
      n = tonumber(n)
      if n and unit == "%" then size = string.format("%.4fem", n / 100)
      elseif n and unit == "em" then size = n .. "em"
      elseif n and unit == "px" then size = string.format("%.2fpt", n * 0.75)
      elseif n and unit == "pt" then size = n .. "pt" end
    end
    local notes = pandoc.Blocks({ pandoc.RawBlock("typst", "#dlm-table-notes(size: " .. size .. ", [") })
    for _, row in ipairs(el.foot.rows) do
      for _, cell in ipairs(row.cells) do
        notes:insert(pandoc.RawBlock("typst", "#block["))
        notes:extend(cell.contents)
        notes:insert(pandoc.RawBlock("typst", "]"))
      end
    end
    notes:insert(pandoc.RawBlock("typst", "])"))
    el.foot.rows = pandoc.List({})
    local out = pandoc.Blocks({ el })
    out:extend(notes)
    return out
  end,
}

-- Short captions for the lists of figures and tables. The short caption is
-- parsed as markdown, matching how Quarto treats `fig-scap` for LaTeX.
local short_caption_filter = {
  FloatRefTarget = function(float)
    if not quarto.doc.is_format("typst") then return nil end
    local scap = float.attributes["fig-scap"] or float.attributes["tbl-scap"]
    if scap == nil or scap == "" or float.caption_long == nil then return nil end

    local short = pandoc.utils.blocks_to_inlines(pandoc.read(scap, "markdown").blocks)
    local long = quarto.utils.as_inlines(float.caption_long)
    local wrapped = pandoc.Inlines({ pandoc.RawInline("typst", "#dlm-flex-caption[") })
    wrapped:extend(long)
    wrapped:insert(pandoc.RawInline("typst", "]["))
    wrapped:extend(short)
    wrapped:insert(pandoc.RawInline("typst", "]"))
    float.caption_long = pandoc.Plain(wrapped)
    return float
  end,
}

-- Continued captions for breakable tables: add an unstyled first header row
-- holding the template's dlm-continued-caption(), which repeats with the
-- header and shows "Table N ... (continued)" on every page after the first.
-- Runs top down so the `breakable` div is seen before the table inside it.
local pending_breakable = false
local continued_caption_filter = {
  traverse = "topdown",
  Div = function(div)
    if quarto.doc.is_format("typst") and div.classes:includes("breakable") then
      pending_breakable = true
    end
    return nil
  end,
  Table = function(el)
    if not pending_breakable then return nil end
    pending_breakable = false
    -- the template styles row 0 as the header; this row takes its place, so
    -- give header cells without their own fill (e.g., markdown tables) the
    -- header style directly
    for _, row in ipairs(el.head.rows) do
      for _, cell in ipairs(row.cells) do
        if not cell.attributes["typst:fill"] then
          cell.attributes["typst:fill"] = "dlm-mist"
          local contents = pandoc.Blocks({
            pandoc.RawBlock("typst", "#[#set text(weight: 650, fill: dlm-navy)"),
          })
          contents:extend(cell.contents)
          contents:insert(pandoc.RawBlock("typst", "]"))
          cell.contents = contents
        end
      end
    end
    local cell = pandoc.Cell(
      { pandoc.RawBlock("typst", "#dlm-continued-caption()") },
      pandoc.AlignDefault, 1, #el.colspecs,
      pandoc.Attr("", {}, {
        ["typst:fill"] = "none",
        ["typst:inset"] = "0pt",
        ["typst:align"] = "left",
      })
    )
    el.head.rows:insert(1, pandoc.Row({ cell }))
    return el
  end,
}

return {
  quarto.utils.combineFilters({
    quarto.utils.file_metadata_filter(),
    header_filter,
    math_alt_filter,
    gt_table_filter,
    short_caption_filter,
  }),
  continued_caption_filter,
}
