local List = require("pandoc.List")

local h1_newpage = true
local normalize_section_color_blocks
local normalize_break_blocks
local cover_defaults = {
  title = "",
  subtitle = "",
  designer = "",
  complexity = "0",
  image = ""
}

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

-- Utility per compatibilità: controlla se una classe è presente
local function includes_class(classes, name)
  if type(classes.includes) == "function" then
    return classes:includes(name)
  end
  for _, c in ipairs(classes) do
    if c == name then return true end
  end
  return false
end

function Span(el)
  if FORMAT ~= "latex" and FORMAT ~= "pdf" then
    return nil
  end
  if includes_class(el.classes, "columnbreak") then
    return pandoc.RawInline("latex", "\\columnbreak")
  end
  if includes_class(el.classes, "pagebreak") then
    return pandoc.RawInline("latex", "\\dghpagebreak")
  end
  return nil
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

local function append_header_include(meta, latex)
  local includes = ensure_header_includes_list(meta)
  includes:insert(pandoc.MetaBlocks({ pandoc.RawBlock("latex", latex) }))
end

local function meta_to_latex(value)
  if value == nil then
    return ""
  end
  if type(value) == "string" then
    return latex_escape(value)
  end
  if value.t == "MetaString" then
    return latex_escape(value.text)
  end

  local value_type = pandoc.utils.type(value)
  local doc = nil
  if value_type == "Inlines" then
    doc = pandoc.Pandoc({ pandoc.Para(value) })
  elseif value_type == "Blocks" then
    doc = pandoc.Pandoc(value)
  else
    return latex_escape(pandoc.utils.stringify(value))
  end

  return pandoc.write(doc, "latex"):gsub("%s+$", "")
end

local function complexity_to_string(value)
  local complexity_num = tonumber(meta_to_string(value))
  if complexity_num then
    complexity_num = math.max(1, math.min(5, math.floor(complexity_num + 0.5)))
  else
    complexity_num = 0
  end
  return tostring(complexity_num)
end

local function trim_inline(text)
  if not text then
    return ""
  end
  return text:match("^%s*(.-)%s*$")
end

local function ensure_cover_defaults_from_meta(meta)
  if not meta then
    return
  end

  local title = pandoc.utils.stringify(meta.title or "")
  if title ~= "" then
    cover_defaults.title = title
  end

  local subtitle = meta_to_latex(meta.subtitle)
  if subtitle ~= "" then
    cover_defaults.subtitle = subtitle
  end

  local designer = pandoc.utils.stringify(meta.designer or "")
  if designer ~= "" then
    cover_defaults.designer = designer
  end

  local complexity = complexity_to_string(meta.complexity)
  if complexity ~= "0" or cover_defaults.complexity == "" then
    cover_defaults.complexity = complexity
  end

  local image = get_meta_string(meta, {
    "cover-image",
    "title-image",
    "titlepage-image"
  }, "")
  if image ~= "" then
    cover_defaults.image = image
  end
end

function Meta(meta)
  if meta["h1-newpage"] ~= nil then
    h1_newpage = meta["h1-newpage"]
  end

  ensure_cover_defaults_from_meta(meta)

  local cover_page_mode = trim_inline(get_meta_string(meta, {
    "cover-page"
  }, "")):lower()
  if cover_page_mode == "custom" then
    meta["custom-cover-page"] = pandoc.MetaBool(true)
  else
    meta["custom-cover-page"] = nil
  end

  if meta["toc-depth"] then
    local depth = pandoc.utils.stringify(meta["toc-depth"])
    append_header_include(meta, "\\setcounter{tocdepth}{" .. depth .. "}")
  end

  local cover_image_title = latex_escape(trim_inline(get_meta_string(meta, {
    "cover-image-title",
    "cover-image-tile"
  }, "")))
  local cover_image_author = latex_escape(trim_inline(get_meta_string(meta, {
    "cover-image-author"
  }, "")))
  local title_enabled = cover_image_title ~= "" and "1" or "0"
  local author_enabled = cover_image_author ~= "" and "1" or "0"
  local credit_enabled = (title_enabled == "1" or author_enabled == "1") and "1" or "0"

  append_header_include(meta, "\\gdef\\dghcoverdesigner{" .. latex_escape(cover_defaults.designer or "") .. "}")
  append_header_include(meta, "\\gdef\\dghcovercomplexity{" .. (cover_defaults.complexity or "0") .. "}")
  append_header_include(meta, "\\gdef\\dghcovertitle{" .. latex_escape(cover_defaults.title or "") .. "}")
  append_header_include(meta, "\\long\\gdef\\dghcoversubtitle{" .. (cover_defaults.subtitle or "") .. "}")
  append_header_include(meta, "\\gdef\\dghcoverimagetitle{" .. cover_image_title .. "}")
  append_header_include(meta, "\\gdef\\dghcoverimageauthor{" .. cover_image_author .. "}")
  append_header_include(meta, "\\gdef\\dghcoverimagetitleenabled{" .. title_enabled .. "}")
  append_header_include(meta, "\\gdef\\dghcoverimageauthorenabled{" .. author_enabled .. "}")
  append_header_include(meta, "\\gdef\\dghcoverimagecreditenabled{" .. credit_enabled .. "}")

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
  doc.blocks = normalize_break_blocks(doc.blocks)

  if not h1_newpage then
    table.insert(doc.blocks, 1, pandoc.RawBlock("latex", "\\dghonepagebreakfalse"))
  end
  return doc
end

local function section_colors_from_header(el)
  local classes = el and el.classes or {}
  local attributes = el and el.attributes or {}

  local has_sectioncolor_class = false
  local h1 = nil
  local h2 = nil

  for _, class_name in ipairs(classes) do
    if class_name == "sectioncolor" then
      has_sectioncolor_class = true
    end
  end

  if has_sectioncolor_class then
    local attr_h1 = trim_inline(attributes["h1"] or attributes["section-h1"])
    local attr_h2 = trim_inline(attributes["h2"] or attributes["section-h2"])

    if attr_h1 ~= "" then
      h1 = attr_h1
    end
    if attr_h2 ~= "" then
      h2 = attr_h2
    end
  else
    return nil, nil
  end

  if h1 and h1 ~= "" and (not h2 or h2 == "") then
    h2 = h1
  elseif (not h1 or h1 == "") and h2 and h2 ~= "" then
    -- If only h2 is provided, keep H1 at the template default color.
    h1 = "h1text"
  end

  return h1, h2
end

function Header(el)
  if el.level == 1 then
    local section_color, subsection_color = section_colors_from_header(el)
    local section_color_before = nil
    local section_color_after = nil

    if (section_color and section_color ~= "") or (subsection_color and subsection_color ~= "") then
      if not section_color or section_color == "" then
        section_color = "h1text"
      end
      if not subsection_color or subsection_color == "" then
        subsection_color = section_color
      end
      section_color_before = pandoc.RawBlock(
        "latex",
        "\\setsectioncolor{" .. section_color .. "}{" .. subsection_color .. "}\n"
          .. "\\global\\dgresetsectioncoloronnextsectionfalse"
      )
      section_color_after = pandoc.RawBlock("latex", "\\global\\dgresetsectioncoloronnextsectiontrue")
    end

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
      local blocks = {}
      if h1_newpage then
        table.insert(blocks, pandoc.RawBlock("latex", "\\newpage"))
      end
      if section_color_before then
        table.insert(blocks, section_color_before)
      end
      table.insert(blocks, section_bg_block)
      if section_color_after then
        table.insert(blocks, section_color_after)
      end
      if #blocks == 1 then
        return blocks[1]
      end
      return blocks
    end

    local out = {}
    if h1_newpage then
      table.insert(out, pandoc.RawBlock("latex", "\\newpage"))
    end
    if section_color_before then
      table.insert(out, section_color_before)
      table.insert(out, el)
      table.insert(out, section_color_after)
      return out
    end
    if #out > 0 then
      table.insert(out, el)
      return out
    end
  end
  return el
end

local function has_class(el, class_name)
  for _, c in ipairs(el.classes or {}) do
    if c == class_name then
      return true
    end
  end
  return false
end

-- Recursively collects all Header blocks from a block list (including nested Divs).
local function collect_all_headers(blocks)
  local headers = {}
  for _, block in ipairs(blocks) do
    if block.t == "Header" then
      table.insert(headers, block)
    elseif block.t == "Div" and block.content then
      local nested = collect_all_headers(block.content)
      for _, h in ipairs(nested) do
        table.insert(headers, h)
      end
    end
  end
  return headers
end

-- Reads a Markdown file and returns headings of `collect_level` found under
-- the first heading of `from_level` whose text matches `under_title`
-- (case-insensitive). If `under_title` is empty/nil, collects from the start.
-- Returns a list of {id, inlines} tables.
local function collect_headings_under(file_path, under_title, from_level, collect_level)
  local f = io.open(file_path, "r")
  if not f then
    return nil, "headerlist: cannot open file: " .. tostring(file_path)
  end
  local content = f:read("*all")
  f:close()

  local doc = pandoc.read(content, "markdown+fenced_divs+bracketed_spans")
  local result = {}

  local scope_active = (under_title == nil or under_title == "")
  local target = under_title and under_title:lower():match("^%s*(.-)%s*$") or ""

  for _, block in ipairs(collect_all_headers(doc.blocks)) do
    if block.level == from_level then
      local title_text = pandoc.utils.stringify(block.content):lower():match("^%s*(.-)%s*$")
      if target == "" then
        scope_active = true
      else
        scope_active = (title_text == target)
      end
    elseif block.level == collect_level and scope_active then
      table.insert(result, { id = block.identifier or "", inlines = block.content })
    end
  end

  return result, nil
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

local function is_break_command(text)
  return text:match("^%s*\\(pagebreak|columnbreak|newpage|clearpage|dghpagebreak)%s*$")
end

normalize_break_blocks = function(blocks)
  local normalized = List:new()
  local last_was_break = false

  for _, block in ipairs(blocks) do
    if block.t == "RawBlock" and block.format == "latex" and is_break_command(block.text) then
      if not last_was_break then
        normalized:insert(block)
        last_was_break = true
      end
      -- Se vuoi sempre inserire, togli il controllo su last_was_break
    else
      normalized:insert(block)
      last_was_break = false
    end
  end

  return normalized
end

local function trim(text)
  if not text then
    return ""
  end
  return text:match("^%s*(.-)%s*$")
end

local function first_non_empty(...)
  for _, value in ipairs({ ... }) do
    if value and value ~= "" then
      return value
    end
  end
  return ""
end

local function get_first_value(values, keys)
  for _, key in ipairs(keys) do
    local value = values[key]
    if type(value) == "string" and value ~= "" then
      return value
    end
  end
  return nil
end

local function inlines_to_config_text(inlines)
  local parts = {}
  for _, inline in ipairs(inlines or {}) do
    if inline.t == "Str" then
      table.insert(parts, inline.text or inline.c or "")
    elseif inline.t == "Space" then
      table.insert(parts, " ")
    elseif inline.t == "SoftBreak" or inline.t == "LineBreak" then
      table.insert(parts, "\n")
    else
      table.insert(parts, pandoc.utils.stringify(inline))
    end
  end
  return table.concat(parts)
end

local function markdown_blocks_to_text(blocks)
  if not blocks or #blocks == 0 then
    return ""
  end

  local lines = {}
  for _, block in ipairs(blocks) do
    if (block.t == "Para" or block.t == "Plain") and block.content then
      local text = inlines_to_config_text(block.content)
      for line in (text .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
      end
    elseif block.t == "BulletList" then
      for _, item in ipairs(block.content or {}) do
        local item_text = markdown_blocks_to_text(item)
        item_text = trim(item_text):gsub("\n+", " ")
        table.insert(lines, "- " .. item_text)
      end
    else
      table.insert(lines, pandoc.utils.stringify(block))
    end
    table.insert(lines, "")
  end

  return table.concat(lines, "\n"):gsub("\r\n", "\n")
end

local function parse_key_value_markdown(blocks)
  local text = markdown_blocks_to_text(blocks)
  local parsed = {}
  local current_list_key = nil

  for line in (text .. "\n"):gmatch("(.-)\n") do
    local raw = trim(line)

    if raw == "" then
      current_list_key = nil
    else
      local key, value = raw:match("^([%a][%w_-]*)%s*:%s*(.-)%s*$")

      if key then
        local normalized_key = key:lower()
        local normalized_value = trim(value)

        if normalized_value == "" then
          parsed[normalized_key] = parsed[normalized_key] or {}
          current_list_key = normalized_key
        else
          parsed[normalized_key] = normalized_value
          current_list_key = nil
        end
      else
        local item = raw:match("^%-%s+(.+)$")
        if item and current_list_key then
          if type(parsed[current_list_key]) ~= "table" then
            parsed[current_list_key] = {}
          end
          table.insert(parsed[current_list_key], trim(item))
        elseif current_list_key and type(parsed[current_list_key]) == "table" and #parsed[current_list_key] > 0 then
          local last_index = #parsed[current_list_key]
          parsed[current_list_key][last_index] = parsed[current_list_key][last_index] .. " " .. raw
        end
      end
    end
  end

  return parsed
end

local function is_markdown_kv_block(parsed, keys)
  for _, key in ipairs(keys) do
    if parsed[key] ~= nil then
      return true
    end
  end
  return false
end

local function build_adversary_stats_from_markdown(parsed)
  local size = latex_escape(get_first_value(parsed, { "size" }) or "")
  local segments = latex_escape(get_first_value(parsed, { "segments" }) or "")
  local difficulty = latex_escape(get_first_value(parsed, { "difficulty" }) or "")
  local thresholds = latex_escape(get_first_value(parsed, { "thresholds" }) or "")
  local hp = latex_escape(get_first_value(parsed, { "hp" }) or "")
  local stress = latex_escape(get_first_value(parsed, { "stress" }) or "")
  local atk = latex_escape(get_first_value(parsed, { "atk" }) or "")

  local weapon_name = ""
  local weapon_details = ""

  local weapons_value = parsed["weapons"]
  if type(weapons_value) == "table" and #weapons_value > 0 then
    local first_weapon = weapons_value[1]
    local name, details = first_weapon:match("^([^:]+):%s*(.+)$")
    if name and details then
      weapon_name = latex_escape(trim(name))
      local range, damage = details:match("^([^|]+)|%s*(.+)$")
      if range and damage then
        weapon_details = latex_escape(trim(range) .. " | " .. trim(damage))
      else
        weapon_details = latex_escape(trim(details))
      end
    else
      weapon_name = "\\dghlabelweapon"
      weapon_details = latex_escape(trim(first_weapon))
    end
  elseif type(weapons_value) == "string" and weapons_value ~= "" then
    weapon_name = "\\dghlabelweapon"
    weapon_details = latex_escape(weapons_value)
  end

  local stats = "\\adversarystats"
    .. latex_arg(size)
    .. latex_arg(segments)
    .. latex_arg(difficulty)
    .. latex_arg(thresholds)
    .. latex_arg(hp)
    .. latex_arg(stress)
    .. latex_arg(atk)
    .. latex_arg(weapon_name)
    .. latex_arg(weapon_details)

  local experience = get_first_value(parsed, { "experience" })
  if experience and experience ~= "" then
    stats = stats
      .. string.rep("\\", 3)
      .. "dghexperienceseparator"
      .. string.rep("\\", 3)
      .. "textbf{\\dghlabelexperience:} "
      .. latex_escape(experience)
  end

  return stats
end

local function build_features_from_markdown(parsed)
  local features_value = parsed["features"]

  if type(features_value) == "table" and #features_value > 0 then
    local items = {}
    for _, item in ipairs(features_value) do
      table.insert(items, "\\textit{\\textbf{-}} " .. latex_escape(item) .. "\\\\")
    end
    return table.concat(items, "\n")
  end

  if type(features_value) == "string" and features_value ~= "" then
    return latex_escape(features_value)
  end

  return ""
end

local function build_environment_stats_from_markdown(parsed)
  local difficulty = latex_escape(get_first_value(parsed, { "difficulty" }) or "")
  local adversaries_value = parsed["adversaries"]
  local adversaries = ""

  if type(adversaries_value) == "table" and #adversaries_value > 0 then
    adversaries = latex_escape(table.concat(adversaries_value, ", "))
  elseif type(adversaries_value) == "string" then
    adversaries = latex_escape(adversaries_value)
  end

  return "\\environmentstats" .. latex_arg(difficulty) .. latex_arg(adversaries)
end

local function latex_image_length(value)
  if not value or value == "" then
    return nil
  end

  local percent = value:match("^%s*([%d%.]+)%%%s*$")
  if percent then
    local ratio = tonumber(percent)
    if ratio then
      if math.abs(ratio - 100) < 0.0001 then
        return "\\linewidth"
      end
      return string.format("%.6f\\linewidth", ratio / 100)
    end
  end

  return value
end

local function image_latex(el)
  local options = {}
  local width = latex_image_length(el.attributes["width"])
  local height = latex_image_length(el.attributes["height"])

  if width then
    table.insert(options, "width=" .. width)
  end

  if height then
    table.insert(options, "height=" .. height)
  end

  table.insert(options, "keepaspectratio")

  return "\\includegraphics[" .. table.concat(options, ",") .. "]{\\detokenize{" .. el.src .. "}}"
end

local function first_image_from_blocks(blocks)
  for _, block in ipairs(blocks or {}) do
    if (block.t == "Plain" or block.t == "Para") and block.content then
      for _, inline in ipairs(block.content) do
        if inline.t == "Image" then
          return inline
        end
      end
    end
  end
  return nil
end

local function cell_blocks(cell)
  if not cell then
    return {}
  end
  if cell.contents then
    return cell.contents
  end
  if cell.content then
    return cell.content
  end
  return {}
end

local function cell_to_latex(cell)
  local latex = blocks_to_latex(cell_blocks(cell))
  latex = latex:gsub("%s*\n%s*", " ")
  latex = latex:gsub("^%s+", "")
  latex = latex:gsub("%s+$", "")
  if latex == "" then
    return "~"
  end
  return latex
end

local function row_cells(row)
  if not row then
    return {}
  end
  if row.cells then
    return row.cells
  end
  return {}
end

local function append_rows(target, rows)
  if not rows then
    return
  end
  for _, r in ipairs(rows) do
    target:insert(r)
  end
end

local function collect_table_rows(tbl)
  local rows = List:new()

  if tbl.head and tbl.head.rows then
    append_rows(rows, tbl.head.rows)
  end

  for _, body in ipairs(tbl.bodies or {}) do
    if body.head and body.head.rows then
      append_rows(rows, body.head.rows)
    elseif body.head then
      append_rows(rows, body.head)
    end

    if body.body then
      append_rows(rows, body.body)
    elseif body.rows then
      append_rows(rows, body.rows)
    end
  end

  if tbl.foot and tbl.foot.rows then
    append_rows(rows, tbl.foot.rows)
  end

  return rows
end

local function default_colspec(col_count)
  if col_count < 1 then
    col_count = 1
  end

  local parts = {}
  for _ = 1, col_count do
    table.insert(parts, ">{\\raggedright\\arraybackslash}X")
  end

  return table.concat(parts, "")
end

function Table(tbl)
  if FORMAT ~= "latex" and FORMAT ~= "pdf" then
    return nil
  end

  local rows = collect_table_rows(tbl)
  if #rows == 0 then
    return nil
  end

  local first_row = rows[1]
  local first_cells = row_cells(first_row)
  local col_count = #first_cells

  if col_count == 0 and tbl.colspecs then
    col_count = #tbl.colspecs
  end
  if col_count == 0 then
    return nil
  end

  local latex_rows = {}
  for row_index, row in ipairs(rows) do
    local cells = row_cells(row)
    local rendered = {}

    for col = 1, col_count do
      local cell = cells[col]
      local value = cell_to_latex(cell)
      if row_index == 1 then
        value = "\\textbf{\\textcolor{white}{" .. value .. "}}"
      end
      table.insert(rendered, value)
    end

    table.insert(latex_rows, table.concat(rendered, " & ") .. " \\\\")
  end

  local latex = "\\ColoredTable"
    .. latex_arg("\\linewidth")
    .. latex_arg("\\dgsectioncolor")
    .. latex_arg(default_colspec(col_count))
    .. latex_arg(table.concat(latex_rows, "\n"))

  return pandoc.RawBlock("latex", latex)
end

function Image(el)
  if FORMAT ~= "latex" and FORMAT ~= "pdf" then
    return nil
  end

  return pandoc.RawInline("latex", image_latex(el))
end

local function figure_caption_text(fig)
  if not fig.caption then
    return ""
  end

  if fig.caption.long then
    return pandoc.utils.stringify(fig.caption.long)
  end

  if fig.caption[2] then
    return pandoc.utils.stringify(fig.caption[2])
  end

  return pandoc.utils.stringify(fig.caption)
end

function Figure(fig)
  if FORMAT ~= "latex" and FORMAT ~= "pdf" then
    return nil
  end

  if fig.content and #fig.content > 0 then
    local image = first_image_from_blocks(fig.content)
    local body = image and image_latex(image) or blocks_to_latex(fig.content)
    local caption = figure_caption_text(fig)

    if caption and caption ~= "" then
      local latex = "\\begin{center}\n"
        .. body
        .. "\\\\[0.4em]\n{\\small\\itshape " .. latex_escape(caption) .. "}\n"
        .. "\\end{center}"
      return pandoc.RawBlock("latex", latex)
    end

    return pandoc.RawBlock("latex", body)
  end

  return pandoc.Null()
end

local function render_environment_box(name, body_latex)
  local out = {}
  table.insert(out, "\\begin{" .. name .. "}")
  table.insert(out, body_latex)
  table.insert(out, "\\end{" .. name .. "}")
  return table.concat(out, "\n")
end

local function strip_yaml_quotes(value)
  if not value then
    return ""
  end

  local text = trim(value)
  if (#text >= 2 and text:sub(1, 1) == '"' and text:sub(-1) == '"')
    or (#text >= 2 and text:sub(1, 1) == "'" and text:sub(-1) == "'") then
    return text:sub(2, -2)
  end

  return text
end

local function parse_statblock_yaml(text)
  local parsed = {}
  parsed.feats = {}
  local in_feats = false
  local current_feat = nil

  for line in (text .. "\n"):gmatch("(.-)\n") do
    local raw = line:gsub("\r", "")

    -- ── Block scalar continuation (text: |) ──────────────────────────────────
    if current_feat and current_feat._block_scalar then
      if raw:match("^%s*$") then
        -- blank line inside block: preserve as empty line for Markdown
        current_feat.text = current_feat.text .. "\n"
        goto continue
      end
      local indent_len = #(raw:match("^(%s*)"))
      if current_feat._block_indent == nil then
        current_feat._block_indent = indent_len
      end
      if indent_len >= current_feat._block_indent then
        local content = raw:sub(current_feat._block_indent + 1)
        current_feat.text = current_feat.text == ""
          and content
          or (current_feat.text .. "\n" .. content)
        goto continue
      else
        -- indent dropped: end of block scalar, fall through to normal parse
        current_feat._block_scalar = false
      end
    end

    -- ── Normal line processing ───────────────────────────────────────────────
    if raw:match("^%s*$") then
      -- skip blank lines
    else
      local top_key, top_value = raw:match("^([%a][%w_]*)%s*:%s*(.-)%s*$")

      if top_key then
        local key = top_key:lower()
        local value = strip_yaml_quotes(top_value)

        if key == "feats" or key == "feature" then
          in_feats = true
          current_feat = nil
        else
          in_feats = false
          current_feat = nil
          parsed[key] = value
        end
      elseif in_feats then
        local feat_name = raw:match("^%s*%-%s*name%s*:%s*(.-)%s*$")
        if feat_name then
          current_feat = {
            name          = strip_yaml_quotes(feat_name),
            text          = "",
            question      = "",
            _block_scalar = false,
            _block_indent = nil,
          }
          table.insert(parsed.feats, current_feat)
        elseif current_feat then
          local feat_question = raw:match("^%s*question%s*:%s*(.-)%s*$")
          local feat_text_raw = raw:match("^%s*text%s*:%s*(.-)%s*$")
          if feat_question then
            current_feat.question = strip_yaml_quotes(feat_question)
          elseif feat_text_raw == "|" then
            -- YAML literal block scalar
            current_feat._block_scalar = true
            current_feat._block_indent = nil
            current_feat.text = ""
          elseif feat_text_raw then
            current_feat.text = trim(feat_text_raw)
          else
            -- plain continuation line
            local continuation = raw:match("^%s+(.+)$")
            if continuation and continuation ~= "" then
              current_feat.text = current_feat.text .. " " .. trim(continuation)
            end
          end
        end
      end
    end

    ::continue::
  end

  return parsed
end

-- Walk a list of Pandoc inline AST nodes → LaTeX string.
local function inlines_to_latex(inlines)
  local buf = {}
  for _, el in ipairs(inlines) do
    if el.t == "Str" then
      buf[#buf+1] = latex_escape(el.text)
    elseif el.t == "Space" or el.t == "SoftBreak" then
      buf[#buf+1] = " "
    elseif el.t == "LineBreak" then
      buf[#buf+1] = "\\\\ "
    elseif el.t == "Strong" then
      buf[#buf+1] = "\\textbf{" .. inlines_to_latex(el.content) .. "}"
    elseif el.t == "Emph" then
      buf[#buf+1] = "\\textit{" .. inlines_to_latex(el.content) .. "}"
    elseif el.t == "Code" then
      buf[#buf+1] = "\\texttt{" .. latex_escape(el.text) .. "}"
    elseif el.t == "RawInline" then
      if el.format == "latex" or el.format == "tex" then
        buf[#buf+1] = el.text
      end
    elseif el.t == "Math" then
      -- DisplayMath ($$...$$) e InlineMath ($...$): passa il contenuto verbatim
      -- così costrutti come $$\vspace{2em}$$ vengono emessi come \vspace{2em}
      buf[#buf+1] = el.text
    else
      buf[#buf+1] = latex_escape(pandoc.utils.stringify(el))
    end
  end
  return table.concat(buf)
end

-- Walk a list of Pandoc block AST nodes → LaTeX string.
-- Blocks are separated by \par (safe for both inline and block-level content).
local function blocks_to_latex(blocks)
  local parts = {}
  for _, block in ipairs(blocks) do
    if block.t == "Para" or block.t == "Plain" then
      parts[#parts+1] = inlines_to_latex(block.content)
    elseif block.t == "RawBlock" then
      if block.format == "latex" or block.format == "tex" then
        parts[#parts+1] = block.text or ""
      end
    elseif block.t == "Header" then
      local rendered = Header(block)
      local header_blocks = rendered
      if rendered == nil then
        header_blocks = { block }
      elseif rendered.t ~= nil then
        header_blocks = { rendered }
      end
      parts[#parts+1] = pandoc.write(pandoc.Pandoc(header_blocks), "latex"):gsub("%s+$", "")
    elseif block.t == "Div" then
      if has_class(block, "center") then
        local body = blocks_to_latex(block.content or {})
        parts[#parts+1] = "\\begin{center}\n" .. body .. "\n\\end{center}"
      elseif has_class(block, "right") then
        local body = blocks_to_latex(block.content or {})
        parts[#parts+1] = "\\begin{flushright}\n" .. body .. "\n\\end{flushright}"
      elseif has_class(block, "pagebreak") then
        parts[#parts+1] = "\\dghpagebreak"
      elseif has_class(block, "columnbreak") then
        parts[#parts+1] = "\\columnbreak"
      elseif has_class(block, "fullpage") then
        local body = blocks_to_latex(normalize_break_blocks(normalize_section_color_blocks(block.content or {})))
        parts[#parts+1] = "\\beginFullpage\n" .. body .. "\n\\finishFullpage"
      else
        parts[#parts+1] = blocks_to_latex(block.content or {})
      end
    elseif block.t == "BulletList" then
      local items = {}
      for _, item_blocks in ipairs(block.content) do
        items[#items+1] = "\\item " .. blocks_to_latex(item_blocks)
      end
      parts[#parts+1] = "\\begin{itemize}\\tightlist\n"
        .. table.concat(items, "\n") .. "\n\\end{itemize}"
    elseif block.t == "HorizontalRule" then
      parts[#parts+1] = "\\dghsectionseparator"
    end
    -- Other block types (headers, code blocks, etc.) are intentionally ignored.
  end
  return table.concat(parts, "\\par\n")
end

-- Convert a Markdown string to LaTeX using the Pandoc AST pipeline.
local function text_to_latex(text)
  if not text or text == "" then return "" end
  local doc = pandoc.read(text, "markdown")
  return blocks_to_latex(doc.blocks)
end

local function render_feats_latex(feats)
  if type(feats) ~= "table" or #feats == 0 then
    return ""
  end

  local out = {}
  for _, feat in ipairs(feats) do
    local name     = latex_escape(feat.name or "")
    local text     = text_to_latex(strip_yaml_quotes(feat.text or ""))
    local question = latex_escape(feat.question or "")

    local entry = ""
    if name ~= "" and text ~= "" then
      entry = "\\textit{\\textbf{" .. name .. ":}} " .. text
    elseif name ~= "" then
      entry = "\\textit{\\textbf{" .. name .. "}}"
    elseif text ~= "" then
      entry = text
    end

    -- The question is always a separate paragraph so it is safe after any block.
    if question ~= "" then
      entry = entry .. "\\par\n\\textit{" .. question .. "}"
    end

    if entry ~= "" then
      out[#out+1] = entry
    end
  end

  -- \par between entries is safe regardless of whether entries contain block
  -- environments (itemize etc.) — unlike \\, which is invalid at paragraph start.
  -- Wrap in a group that tightens \parskip so the spacing inside the statblock
  -- box stays compact regardless of the document-level parskip setting.
  local body = table.concat(out, "\\par\n")
  return "{\\setlength{\\parskip}{3pt}\\setlength{\\parindent}{0pt}" .. body .. "\\par\\vspace{-\\parskip}}"
end

local function render_adversary_statblock(parsed)
  local title = latex_escape(parsed.name or "")

  local tier_text = ""
  local tier = strip_yaml_quotes(parsed.tier or "")
  local kind = strip_yaml_quotes(parsed.type or "")
  local adjacent = strip_yaml_quotes(parsed.adjacent or "")
  local kind_lower = kind:lower()
  
  if adjacent ~= "" then
    tier_text = "\\dghformatadjacentsegments{" .. latex_escape(adjacent) .. "}"
  elseif tier ~= "" and kind ~= "" then
    tier_text = "\\dghenvironmenttiertype{" .. latex_escape(tier) .. "}{" .. latex_escape(kind) .. "}"
  elseif tier ~= "" then
    tier_text = "\\dghlabeltier{} " .. latex_escape(tier)
  else
    tier_text = latex_escape(kind)
  end

  local summary = latex_escape(parsed.description or "")
  local motives = latex_escape(parsed.motives_and_tactics or parsed.tactics or "")

  local size = latex_escape(parsed.size or "")
  local segments = latex_escape(parsed.segments or "")

  local stats = "\\adversarystats"
    .. latex_arg(size)
    .. latex_arg(segments)
    .. latex_arg(latex_escape(parsed.difficulty or ""))
    .. latex_arg(latex_escape(parsed.thresholds or ""))
    .. latex_arg(latex_escape(parsed.hp or ""))
    .. latex_arg(latex_escape(parsed.stress or ""))
    .. latex_arg(latex_escape(parsed.atk or ""))
    .. latex_arg(latex_escape(parsed.attack or ""))
    .. latex_arg((function()
      local range = latex_escape(parsed.range or "")
      local damage = latex_escape(parsed.damage or "")
      if range ~= "" and damage ~= "" then
        return range .. " | " .. damage
      end
      if range ~= "" then
        return range
      end
      return damage
    end)())

  local experience = strip_yaml_quotes(parsed.experience or "")
  if experience ~= "" then
    stats = stats
      .. string.rep("\\", 3)
      .. "dghexperienceseparator"
      .. string.rep("\\", 3)
      .. "textbf{\\dghlabelexperience:} "
      .. latex_escape(experience)
  end

  local features = render_feats_latex(parsed.feats)

  local is_colossus = false
  if kind_lower:find("colosso", 1, true) or kind_lower:find("colossus", 1, true) then
    is_colossus = true
  end

  local macro = "\\adversary"
  if is_colossus then
    macro = "\\colossusadversary"
  end

  return macro
    .. latex_arg(title)
    .. latex_arg(tier_text)
    .. latex_arg(summary)
    .. latex_arg(motives)
    .. latex_arg(stats)
    .. latex_arg(features)
end

local function render_environment_statblock(parsed)
  local title = latex_escape(parsed.name or "")

  local tier_text = ""
  local tier = strip_yaml_quotes(parsed.tier or "")
  local kind = strip_yaml_quotes(parsed.type or "")
  if tier ~= "" and kind ~= "" then
    tier_text = "\\dghenvironmenttiertype{" .. latex_escape(tier) .. "}{" .. latex_escape(kind) .. "}"
  elseif tier ~= "" then
    tier_text = "\\dghlabeltier{} " .. latex_escape(tier)
  else
    tier_text = latex_escape(kind)
  end

  local summary = latex_escape(parsed.description or "")
  local impulses = latex_escape(parsed.impulses or "")
  local potential_adversaries = latex_escape(parsed.potential_adversaries or parsed.adversaries or "")

  local stats = "\\environmentstats"
    .. latex_arg(latex_escape(parsed.difficulty or ""))
    .. latex_arg(potential_adversaries)

  local features = render_feats_latex(parsed.feats)

  return "\\environment"
    .. latex_arg(title)
    .. latex_arg(tier_text)
    .. latex_arg(summary)
    .. latex_arg(impulses)
    .. latex_arg(stats)
    .. latex_arg(features)
end

function CodeBlock(el)
  if FORMAT ~= "latex" and FORMAT ~= "pdf" then
    return nil
  end

  if not has_class(el, "statblock") then
    return nil
  end

  local parsed = parse_statblock_yaml(el.text or "")
  local layout = (parsed.layout or ""):lower()

  if layout == "daggerheart adversary" then
    return pandoc.RawBlock("latex", render_adversary_statblock(parsed))
  end

  if layout == "daggerheart environment" then
    return pandoc.RawBlock("latex", render_environment_statblock(parsed))
  end

  return nil
end

function Div(div)
  if has_class(div, "headerlist") then
    local parsed = parse_key_value_markdown(div.content)

    local src = trim(first_non_empty(
      attr_value(div, { "src", "file", "path" }, ""),
      get_first_value(parsed, { "src", "file", "path" })
    ))
    if src == "" then
      return pandoc.RawBlock("latex", "% headerlist: missing src attribute")
    end

    local under = trim(first_non_empty(
      attr_value(div, { "under", "section" }, ""),
      get_first_value(parsed, { "under", "section" })
    ))

    local from_level = tonumber(first_non_empty(
      attr_value(div, { "from" }, ""),
      get_first_value(parsed, { "from" })
    )) or 1

    local collect_level = tonumber(first_non_empty(
      attr_value(div, { "collect" }, ""),
      get_first_value(parsed, { "collect" })
    )) or (from_level + 1)

    -- Resolve relative to the first input file's directory
    local base_dir = ""
    if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
      local first = PANDOC_STATE.input_files[1]
      base_dir = first:match("^(.*[/\\])") or ""
    end
    local full_path = base_dir .. src

    local items, err = collect_headings_under(full_path, under, from_level, collect_level)

    if err then
      io.stderr:write(err .. "\n")
      return pandoc.RawBlock("latex", "% " .. err)
    end

    if #items == 0 then
      return pandoc.RawBlock("latex", "% headerlist: no headings found")
    end

    -- Emit a LaTeX itemize with \hyperlink for clickable entries
    local out = { "\\begin{itemize}" }
    for _, entry in ipairs(items) do
      local label = entry.id ~= "" and entry.id or ""
      local text  = latex_escape(pandoc.utils.stringify(entry.inlines))
      if label ~= "" then
        table.insert(out, "  \\item \\hyperlink{" .. label .. "}{" .. text .. "}")
      else
        table.insert(out, "  \\item " .. text)
      end
    end
    table.insert(out, "\\end{itemize}")

    return pandoc.RawBlock("latex", table.concat(out, "\n"))
  end

  if has_class(div, "framecoverpage") then
    if FORMAT ~= "latex" and FORMAT ~= "pdf" then
      return nil
    end

    ensure_cover_defaults_from_meta(PANDOC_STATE.meta)

    local title_value = first_non_empty(
      div.attributes["title"],
      cover_defaults.title
    )
    local title = title_value ~= "" and latex_escape(title_value) or "\\dghcovertitle"

    local subtitle_value = first_non_empty(
      div.attributes["subtitle"],
      cover_defaults.subtitle
    )
    local subtitle = subtitle_value ~= "" and latex_escape(subtitle_value) or "\\dghcoversubtitle"

    local designer_value = first_non_empty(
      div.attributes["designer"],
      cover_defaults.designer
    )
    local designer = designer_value ~= "" and latex_escape(designer_value) or "\\dghcoverdesigner"

    local complexity_value = first_non_empty(
      div.attributes["complexity"],
      cover_defaults.complexity,
      "0"
    )
    local complexity = (complexity_value ~= "" and complexity_value ~= "0")
      and complexity_to_string(complexity_value)
      or "\\dghcovercomplexity"

    local image_path = first_non_empty(
      div.attributes["cover-image"],
      div.attributes["image"],
      cover_defaults.image
    )
    local image = (image_path ~= "") and ("\\detokenize{" .. image_path .. "}") or "\\dghtitleimagepath"

    local body = blocks_to_latex(div.content)
    local out = {}
    table.insert(out, "\\end{multicols}")
    table.insert(out,
      "\\begin{framecoverpage}"
      .. latex_arg(title)
      .. latex_arg(subtitle)
      .. latex_arg(designer)
      .. latex_arg(complexity)
      .. latex_arg(image)
    )
    table.insert(out, body)
    table.insert(out, "\\end{framecoverpage}")
    table.insert(out, "\\begin{multicols}{2}")
    table.insert(out, "\\raggedcolumns")
    return pandoc.RawBlock("latex", table.concat(out, "\n"))
  end

  if has_class(div, "fullpagemap") then
    local parsed = parse_key_value_markdown(div.content)
    local src = trim(first_non_empty(
      attr_value(div, { "src", "path", "file" }, ""),
      get_first_value(parsed, { "src", "path", "file" })
    ))
    if src == "" then
      return nil
    end

    local angle = trim(first_non_empty(
      attr_value(div, { "rotate", "angle" }, ""),
      get_first_value(parsed, { "rotate", "angle" }),
      "0"
    ))
    local fit = trim(first_non_empty(
      attr_value(div, { "fit" }, ""),
      get_first_value(parsed, { "fit" }),
      "contain"
    ))
    local width = "\\paperwidth"
    local height = "\\paperheight"

    local out = {}
    table.insert(out, "\\beginFullpage")
    table.insert(out, "\\newpage")
    table.insert(out, "\\thispagestyle{empty}")

    local rotate_node = ""
    local img_w, img_h
    if angle ~= "0" then
      rotate_node = "rotate=" .. angle .. ","
      img_w = "\\paperheight"
      img_h = "\\paperwidth"
    else
      img_w = "\\paperwidth"
      img_h = "\\paperheight"
    end

    local graphic_options = "width=" .. img_w .. ",height=" .. img_h
    if fit ~= "fill" then
      graphic_options = graphic_options .. ",keepaspectratio"
    end

    table.insert(out, "\\begin{tikzpicture}[remember picture,overlay]")
    table.insert(out, "  \\node[" .. rotate_node .. "anchor=center,inner sep=0pt] at (current page.center) {")
    table.insert(out, "    \\includegraphics[" .. graphic_options .. "]{\\detokenize{" .. src .. "}}")
    table.insert(out, "  };")
    table.insert(out, "\\end{tikzpicture}")
    table.insert(out, "\\null")
    table.insert(out, "\\finishFullpage")

    return pandoc.RawBlock("latex", table.concat(out, "\n"))
  end

  if has_class(div, "squarebox") then
    local body = blocks_to_latex(div.content)
    local latex = "\\colorlet{squareboxbg}{\\dgsectioncolor!15}\n"
      .. "\\colorlet{squareboxborder}{\\dgsectioncolor}\n"
      .. render_environment_box("squarebox", body)
      .. "\n\\resetboxcolor"
    return pandoc.RawBlock("latex", latex)
  end

  if has_class(div, "roundedbox") then
    return pandoc.RawBlock("latex", render_environment_box("roundedbox", blocks_to_latex(div.content)))
  end

  if has_class(div, "quotebox") then
    return pandoc.RawBlock("latex", render_environment_box("quotebox", blocks_to_latex(div.content)))
  end

  if has_class(div, "fullpage") then
    local body = blocks_to_latex(normalize_break_blocks(normalize_section_color_blocks(div.content)))
    local latex = "\\beginFullpage\n" .. body .. "\n\\finishFullpage"
    return pandoc.RawBlock("latex", latex)
  end

  if has_class(div, "columnbreak") then
    return pandoc.RawBlock("latex", "\\columnbreak")
  end

  if has_class(div, "pagebreak") then
    return pandoc.RawBlock("latex", "\\dghpagebreak")
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
