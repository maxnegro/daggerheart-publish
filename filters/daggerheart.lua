local List = require("pandoc.List")

local h1_newpage = true
local normalize_section_color_blocks

local function meta_to_string(value)
  if value == nil then
    return nil
  end

  if type(value) == "string" then
    return value
  end

  if value.t == "MetaString" then
    return value.text
  end

  if value.t == "MetaInlines" or value.t == "MetaBlocks" then
    return pandoc.utils.stringify(value)
  end

  return pandoc.utils.stringify(value)
end

local function get_meta_string(meta, keys, default)
  for _, key in ipairs(keys) do
    local value = meta_to_string(meta[key])
    if value and value ~= "" then
      return value
    end
  end
  return default
end

local function ensure_header_includes_list(meta)
  local includes = meta["header-includes"]

  if not includes then
    includes = pandoc.MetaList({})
  elseif includes.t ~= "MetaList" then
    includes = pandoc.MetaList({ includes })
  end

  meta["header-includes"] = includes
  return includes
end

local function append_header_include(meta, latex)
  local includes = ensure_header_includes_list(meta)
  includes:insert(pandoc.MetaBlocks({ pandoc.RawBlock("latex", latex) }))
end

function Meta(meta)
  if meta["h1-newpage"] ~= nil then
    h1_newpage = meta["h1-newpage"]
  end

  local title_image = get_meta_string(meta, {
    "title-image",
    "titlepage-image",
    "cover-image"
  }, nil)

  if title_image and title_image ~= "" then
    local mode = get_meta_string(meta, {
      "title-image-mode",
      "titlepage-image-mode"
    }, "half")

    local image_height = get_meta_string(meta, {
      "title-image-height",
      "titlepage-image-height"
    }, "0.5\\paperheight")

    local fit = get_meta_string(meta, {
      "title-image-fit",
      "titlepage-image-fit"
    }, "fill")

local position = get_meta_string(meta, {
        "title-image-position",
        "titlepage-image-position"
      }, nil)

      append_header_include(meta, "\\settitlepageimagemode{" .. mode .. "}")
      append_header_include(meta, "\\settitlepageimageheight{" .. image_height .. "}")
      append_header_include(meta, "\\settitlepageimagefit{" .. fit .. "}")
      if position and position ~= "" then
        append_header_include(meta, "\\settitlepageimageposition{" .. position .. "}")
      end
    append_header_include(meta, "\\settitlepageimagepath{\\detokenize{" .. title_image .. "}}")
  end

  return meta
end

function Pandoc(doc)
  doc.blocks = normalize_section_color_blocks(doc.blocks)

  if not h1_newpage then
    table.insert(doc.blocks, 1, pandoc.RawBlock("latex", "\\dghonepagebreakfalse"))
  end
  return doc
end

function Header(el)
  if el.level == 1 then
    local bg = el.attributes["bg"] or el.attributes["background"] or el.attributes["section-bg"]
    if bg and bg ~= "" then
      local bg_height = el.attributes["bg-height"] or el.attributes["section-bg-height"]
      local bg_raise = el.attributes["bg-raise"] or el.attributes["section-bg-raise"]
      local inlines_doc = pandoc.Pandoc({pandoc.Plain(el.content)})
      local title_latex = pandoc.write(inlines_doc, "latex"):gsub("%s*\n%s*", " "):gsub("^%s+", ""):gsub("%s+$", "")
      local out = {}
      if bg_height and bg_height ~= "" then
        table.insert(out, "\\setlength{\\dghsectionbgheight}{" .. bg_height .. "}")
      else
        table.insert(out, "\\setlength{\\dghsectionbgheight}{150pt}")
      end
      if bg_raise and bg_raise ~= "" then
        table.insert(out, "\\setlength{\\dghsectionbgraise}{" .. bg_raise .. "}")
      else
        table.insert(out, "\\setlength{\\dghsectionbgraise}{-18pt}")
      end
      -- Use explicit bg-fade-offset when provided, otherwise default to bg-height-80pt.
      local bg_fade = el.attributes["bg-fade-offset"]
      if bg_fade and bg_fade ~= "" then
        table.insert(out, "\\setlength{\\dghsectionbgfadeoffset}{" .. bg_fade .. "}")
      else
        table.insert(out, "\\setlength{\\dghsectionbgfadeoffset}{\\dimexpr\\dghsectionbgheight-80pt\\relax}")
      end
      table.insert(out, "\\sectionwithbg{" .. bg .. "}{" .. title_latex .. "}")
      local section_bg_block = pandoc.RawBlock("latex", table.concat(out, "\n"))
      if h1_newpage then
        return {
          pandoc.RawBlock("latex", "\\newpage"),
          section_bg_block
        }
      end
      return section_bg_block
    end
    if h1_newpage then
      return {
        pandoc.RawBlock("latex", "\\newpage"),
        el
      }
    end
  end
  return el
end

local function has_class(el, class_name)
  for _, c in ipairs(el.classes) do
    if c == class_name then
      return true
    end
  end
  return false
end

local function latex_escape(text)
  if not text or text == "" then
    return ""
  end

  local replacements = {
    ["\\"] = "\\textbackslash{}",
    ["{"] = "\\{",
    ["}"] = "\\}",
    ["$"] = "\\$",
    ["&"] = "\\&",
    ["#"] = "\\#",
    ["_"] = "\\_",
    ["%"] = "\\%",
    ["~"] = "\\textasciitilde{}",
    ["^"] = "\\textasciicircum{}"
  }

  return (text:gsub("[\\{}$&#_%%~^]", replacements))
end

local function blocks_to_latex(blocks)
  if not blocks or #blocks == 0 then
    return ""
  end

  local doc = pandoc.Pandoc(blocks)
  local latex = pandoc.write(doc, "latex")
  return latex:gsub("%s+$", "")
end

local function latex_arg(text)
  return "{" .. (text or "") .. "}"
end

local function attr_value(el, keys, default)
  for _, key in ipairs(keys) do
    local value = el.attributes[key]
    if value and value ~= "" then
      return value
    end
  end
  return default
end

normalize_section_color_blocks = function(blocks)
  local normalized = List:new()
  local index = 1

  while index <= #blocks do
    local block = blocks[index]
    local next_block = blocks[index + 1]

    if block.t == "RawBlock"
      and block.format == "latex"
      and block.text:match("^%s*\\setsectioncolor%b{}%b{}%s*$")
      and next_block
      and next_block.t == "Header"
      and next_block.level == 1 then
      normalized:insert(next_block)
      normalized:insert(block)
      index = index + 2
    else
      normalized:insert(block)
      index = index + 1
    end
  end

  return normalized
end

local function attr_or_empty(el, keys)
  for _, key in ipairs(keys) do
    local value = el.attributes[key]
    if value and value ~= "" then
      return latex_escape(value)
    end
  end
  return ""
end

local function render_environment_box(name, body_latex)
  local out = {}
  table.insert(out, "\\begin{" .. name .. "}")
  table.insert(out, body_latex)
  table.insert(out, "\\end{" .. name .. "}")
  return table.concat(out, "\n")
end

local function split_adversary_content(div)
  local stats_blocks = List:new()
  local feature_blocks = List:new()
  local body_blocks = List:new()

  for _, block in ipairs(div.content) do
    if block.t == "Div" and has_class(block, "stats") then
      for _, nested in ipairs(block.content) do
        stats_blocks:insert(nested)
      end
    elseif block.t == "Div" and has_class(block, "features") then
      for _, nested in ipairs(block.content) do
        feature_blocks:insert(nested)
      end
    else
      body_blocks:insert(block)
    end
  end

  return stats_blocks, feature_blocks, body_blocks
end

local function split_environment_content(div)
  local stats_blocks = List:new()
  local feature_blocks = List:new()
  local body_blocks = List:new()

  for _, block in ipairs(div.content) do
    if block.t == "Div" and has_class(block, "stats") then
      for _, nested in ipairs(block.content) do
        stats_blocks:insert(nested)
      end
    elseif block.t == "Div" and has_class(block, "features") then
      for _, nested in ipairs(block.content) do
        feature_blocks:insert(nested)
      end
    else
      body_blocks:insert(block)
    end
  end

  return stats_blocks, feature_blocks, body_blocks
end

function Div(div)
  if has_class(div, "fullpagemap") then
    local src = attr_value(div, { "src", "path", "file" }, "")
    if src == "" then
      return nil
    end

    local angle = attr_value(div, { "rotate", "angle" }, "0")
    local fit = attr_value(div, { "fit" }, "contain")
    local width = "\\paperwidth"
    local height = "\\paperheight"

    local out = {}
    table.insert(out, "\\beginFullpage")
    table.insert(out, "\\newgeometry{left=0mm,right=0mm,top=0mm,bottom=0mm}")
    table.insert(out, "\\csname thispagestyle\\endcsname{empty}")

    local graphic_options = "angle=" .. angle .. ",width=" .. width .. ",height=" .. height
    if fit ~= "fill" then
      graphic_options = graphic_options .. ",keepaspectratio"
    end

    table.insert(out, "\\noindent\\includegraphics[" .. graphic_options .. "]{\\detokenize{" .. src .. "}}")
    table.insert(out, "\\restoregeometry")
    table.insert(out, "\\finishFullpage")

    return pandoc.RawBlock("latex", table.concat(out, "\n"))
  end

  if has_class(div, "squarebox") then
    return pandoc.RawBlock("latex", render_environment_box("squarebox", blocks_to_latex(div.content)))
  end

  if has_class(div, "roundedbox") then
    return pandoc.RawBlock("latex", render_environment_box("roundedbox", blocks_to_latex(div.content)))
  end

  if has_class(div, "quotebox") then
    return pandoc.RawBlock("latex", render_environment_box("quotebox", blocks_to_latex(div.content)))
  end

  if has_class(div, "fullpage") then
    local body = blocks_to_latex(normalize_section_color_blocks(div.content))
    local latex = "\\beginFullpage\n" .. body .. "\n\\finishFullpage"
    return pandoc.RawBlock("latex", latex)
  end

  if has_class(div, "adversary") then
    local stats_blocks, feature_blocks, body_blocks = split_adversary_content(div)

    local title = attr_or_empty(div, { "title", "name" })
    local tier = attr_or_empty(div, { "tier", "type" })
    local summary = attr_or_empty(div, { "summary", "description", "desc" })
    local motives = attr_or_empty(div, { "motives", "tactics" })

    local stats = blocks_to_latex(stats_blocks)

    local features_blocks = List:new()
    for _, b in ipairs(body_blocks) do
      features_blocks:insert(b)
    end
    for _, b in ipairs(feature_blocks) do
      features_blocks:insert(b)
    end

    local features = blocks_to_latex(features_blocks)

    local latex = "\\adversary"
      .. latex_arg(title)
      .. latex_arg(tier)
      .. latex_arg(summary)
      .. latex_arg(motives)
      .. latex_arg(stats)
      .. latex_arg(features)

    return pandoc.RawBlock("latex", latex)
  end

  if has_class(div, "environment") then
    local stats_blocks, feature_blocks, body_blocks = split_environment_content(div)

    local title = attr_or_empty(div, { "title", "name" })
    local tier = attr_or_empty(div, { "tier", "type" })
    local summary = attr_or_empty(div, { "summary", "description", "desc" })
    local impulses = attr_or_empty(div, { "impulses" })

    local stats = blocks_to_latex(stats_blocks)

    local features_blocks = List:new()
    for _, b in ipairs(body_blocks) do
      features_blocks:insert(b)
    end
    for _, b in ipairs(feature_blocks) do
      features_blocks:insert(b)
    end

    local features = blocks_to_latex(features_blocks)

    local latex = "\\environment"
      .. latex_arg(title)
      .. latex_arg(tier)
      .. latex_arg(summary)
      .. latex_arg(impulses)
      .. latex_arg(stats)
      .. latex_arg(features)

    return pandoc.RawBlock("latex", latex)
  end

  if has_class(div, "columnbreak") then
    return pandoc.RawBlock("latex", "\\columnbreak")
  end

  if has_class(div, "pagebreak") then
    return pandoc.RawBlock("latex", "\\pagebreak")
  end

  if FORMAT == "latex" or FORMAT == "pdf" then
    if has_class(div, "right") then
      local body = blocks_to_latex(div.content)
      return pandoc.RawBlock("latex", "\\begin{flushright}\n" .. body .. "\n\\end{flushright}")
    end

    if has_class(div, "center") then
      local body = blocks_to_latex(div.content)
      return pandoc.RawBlock("latex", "\\begin{center}\n" .. body .. "\n\\end{center}")
    end
  end

  return nil
end
