--[[
dlm-fig-note.lua
Figure notes. A `fig-note` chunk option (or attribute on a `#fig-` div) adds an
APA-style "*Note*. ..." paragraph directly below the figure caption. The note
is parsed as markdown. The chunk option needs the knitr option hook in the
project's _common.R, because knitr claims `fig.note` for itself and Quarto
does not pass it through.

  * Typst: `dlm-fig-note[...]` from the template, which is left out of the
    list of figures
  * HTML: a `span.dlm-fig-note` styled as its own block in the caption
  * other formats: a line break and the note at the end of the caption
]]

local function note_inlines(text)
  local body = pandoc.utils.blocks_to_inlines(pandoc.read(text, "markdown").blocks)
  local note = pandoc.Inlines({ pandoc.Emph("Note"), pandoc.Str("."), pandoc.Space() })
  note:extend(body)
  return note, body
end

local function add_note(float, text)
  if text == nil or text == "" then return nil end
  float.attributes["fig-note"] = nil

  local caption = pandoc.Inlines({})
  if float.caption_long ~= nil then
    caption = quarto.utils.as_inlines(float.caption_long)
  end
  local note, body = note_inlines(text)

  if quarto.doc.is_format("typst") then
    caption:insert(pandoc.RawInline("typst", "#dlm-fig-note["))
    caption:extend(body)
    caption:insert(pandoc.RawInline("typst", "]"))
  elseif quarto.doc.is_format("html") then
    caption:insert(pandoc.Span(note, { class = "dlm-fig-note" }))
  else
    caption:insert(pandoc.LineBreak())
    caption:extend(note)
  end

  float.caption_long = pandoc.Plain(caption)
  return float
end

-- Walk top down so a code cell is seen before the figure inside it. A note on
-- the cell (chunk option) is held until that figure; a note on the figure
-- itself (div attribute) wins.
local pending = nil

return {
  {
    traverse = "topdown",
    Div = function(div)
      if div.classes:includes("cell") then
        pending = div.attributes["fig-note"]
        if pending ~= nil then
          div.attributes["fig-note"] = nil
          return div
        end
      end
      return nil
    end,
    FloatRefTarget = function(float)
      local text = float.attributes["fig-note"] or pending
      pending = nil
      return add_note(float, text)
    end,
  },
}
