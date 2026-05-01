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
  for _, c in ipairs(el.classes or {}) do
    if c == class_name then
      return true
    end
  end
  return false
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
  local difficulty = latex_escape(get_first_value(parsed, { "difficulty" }) or "")
  local thresholds = latex_escape(get_first_value(parsed, { "thresholds" }) or "")
  local hp = latex_escape(get_first_value(parsed, { "hp" }) or "")
  local stress = latex_escape(get_first_value(parsed, { "stress" }) or "")
  local atk = latex_escape(get_first_value(parsed, { "atk" }) or "")

  local weapon_name = ""
  local weapon_range = ""
  local weapon_damage = ""

  local weapons_value = parsed["weapons"]
  if type(weapons_value) == "table" and #weapons_value > 0 then
    local first_weapon = weapons_value[1]
    local name, details = first_weapon:match("^([^:]+):%s*(.+)$")
    if name and details then
      weapon_name = latex_escape(trim(name))
      local range, damage = details:match("^([^|]+)|%s*(.+)$")
      if range and damage then
        weapon_range = latex_escape(trim(range))
        weapon_damage = latex_escape(trim(damage))
      else
        weapon_range = latex_escape(trim(details))
      end
    else
      weapon_name = "\\dghlabelweapon"
      weapon_range = latex_escape(trim(first_weapon))
    end
  elseif type(weapons_value) == "string" and weapons_value ~= "" then
    weapon_name = "\\dghlabelweapon"
    weapon_range = latex_escape(weapons_value)
  end

  local stats = "\\adversarystats"
    .. latex_arg(difficulty)
    .. latex_arg(thresholds)
    .. latex_arg(hp)
    .. latex_arg(stress)
    .. latex_arg(atk)
    .. latex_arg(weapon_name)
    .. latex_arg(weapon_range)
    .. latex_arg(weapon_damage)

  local experience = get_first_value(parsed, { "experience" })
  if experience and experience ~= "" then
    stats = stats
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
      table.insert(items, "\\textbf{-} " .. latex_escape(item) .. "\\\\")
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

    if raw:match("^%s*$") then
      -- skip
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
            name = strip_yaml_quotes(feat_name),
            text = "",
            question = ""
          }
          table.insert(parsed.feats, current_feat)
        else
          local feat_text = raw:match("^%s*text%s*:%s*(.-)%s*$")
          local feat_question = raw:match("^%s*question%s*:%s*(.-)%s*$")
          if feat_question and current_feat then
            current_feat.question = strip_yaml_quotes(feat_question)
          elseif feat_text and current_feat then
            current_feat.text = trim(feat_text)
          elseif current_feat then
            local continuation = raw:match("^%s+(.+)$")
            if continuation and continuation ~= "" then
              current_feat.text = current_feat.text .. " " .. trim(continuation)
            end
          end
        end
      end
    end
  end

  return parsed
end

local function markdown_inline_to_latex(text)
  if not text or text == "" then
    return ""
  end

  local result = {}
  local i = 1
  local len = #text

  while i <= len do
    if text:sub(i, i+1) == "**" then
      local close = text:find("%*%*", i+2)
      if close then
        table.insert(result, "\\textbf{" .. latex_escape(text:sub(i+2, close-1)) .. "}")
        i = close + 2
      else
        local next_star = text:find("%*", i+1)
        if next_star then
          table.insert(result, latex_escape(text:sub(i, next_star-1)))
          i = next_star
        else
          table.insert(result, latex_escape(text:sub(i)))
          break
        end
      end
    elseif text:sub(i, i) == "*" then
      local close = text:find("%*", i+1)
      if close then
        table.insert(result, "\\textit{" .. latex_escape(text:sub(i+1, close-1)) .. "}")
        i = close + 1
      else
        table.insert(result, latex_escape(text:sub(i)))
        break
      end
    elseif text:sub(i, i) == "_" then
      local close = text:find("_", i+1, true)
      if close then
        table.insert(result, "\\textit{" .. latex_escape(text:sub(i+1, close-1)) .. "}")
        i = close + 1
      else
        table.insert(result, latex_escape(text:sub(i)))
        break
      end
    else
      local next_special = text:find("[%*_]", i)
      if next_special then
        table.insert(result, latex_escape(text:sub(i, next_special-1)))
        i = next_special
      else
        table.insert(result, latex_escape(text:sub(i)))
        break
      end
    end
  end

  return table.concat(result)
end

local function render_feats_latex(feats)
  if type(feats) ~= "table" or #feats == 0 then
    return ""
  end

  local out = {}
  for _, feat in ipairs(feats) do
    local name = latex_escape(feat.name or "")
    local text = markdown_inline_to_latex(strip_yaml_quotes(feat.text or ""))
    local question = latex_escape(feat.question or "")
    local entry = ""
    if name ~= "" and text ~= "" then
      entry = "\\textbf{" .. name .. ":} " .. text
    elseif name ~= "" then
      entry = "\\textbf{" .. name .. "}"
    elseif text ~= "" then
      entry = text
    end
    if question ~= "" then
      entry = entry .. "\\\\\\textit{" .. question .. "}"
    end
    if entry ~= "" then
      table.insert(out, entry .. "\\\\")
    end
  end

  return table.concat(out, "\n")
end

local function render_adversary_statblock(parsed)
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
  local motives = latex_escape(parsed.motives_and_tactics or parsed.tactics or "")

  local stats = "\\adversarystats"
    .. latex_arg(latex_escape(parsed.difficulty or ""))
    .. latex_arg(latex_escape(parsed.thresholds or ""))
    .. latex_arg(latex_escape(parsed.hp or ""))
    .. latex_arg(latex_escape(parsed.stress or ""))
    .. latex_arg(latex_escape(parsed.atk or ""))
    .. latex_arg(latex_escape(parsed.attack or ""))
    .. latex_arg(latex_escape(parsed.range or ""))
    .. latex_arg(latex_escape(parsed.damage or ""))

  local experience = strip_yaml_quotes(parsed.experience or "")
  if experience ~= "" then
    stats = stats
      .. string.rep("\\", 3)
      .. "textbf{\\dghlabelexperience:} "
      .. latex_escape(experience)
  end

  local features = render_feats_latex(parsed.feats)

  return "\\adversary"
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
