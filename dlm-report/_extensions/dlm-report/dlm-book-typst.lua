--[[
dlm-book-typst.lua
Part and appendix handling for Typst *books* rendered with the DLM format.
Quarto marks every chapter of a book with file metadata; level-1 headings of
parts and appendices are swapped for calls into the DLM Typst template.

Also gives every equation alt text (its TeX source), which PDF/UA-1 requires,
and drops gt's default styling from gt tables so the template's table design
applies (styling added with gt::tab_style() is kept).
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

local function clean_gt_css(style)
  local kept = {}
  for decl in style:gmatch("[^;]+") do
    local prop, value = decl:match("^%s*([%w%-]+)%s*:%s*(.-)%s*$")
    if prop then
      prop = prop:lower()
      local drop = gt_drop_props[prop]
        or prop:match("^%-") or prop:match("^margin") or prop:match("^padding")
        or prop:match("^border") or prop:match("^overflow")
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

local gt_table_filter = {
  Table = function(el)
    if not quarto.doc.is_format("typst") or not el.classes:includes("gt_table") then return nil end
    clean_gt_attrs(el.attributes)
    local function rows(list)
      for _, row in ipairs(list) do
        clean_gt_attrs(row.attributes)
        for _, cell in ipairs(row.cells) do clean_gt_attrs(cell.attributes) end
      end
    end
    rows(el.head.rows)
    for _, body in ipairs(el.bodies) do
      rows(body.head)
      rows(body.body)
    end
    rows(el.foot.rows)
    return el
  end,
}

return quarto.utils.combineFilters({
  quarto.utils.file_metadata_filter(),
  header_filter,
  math_alt_filter,
  gt_table_filter,
})
