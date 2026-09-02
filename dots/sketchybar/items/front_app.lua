local colors = require("colors").sections.focused_window
local Frame = require("helpers.frame")
local icon_map = require("helpers.icon_map")
local settings = require("settings")
local appearance = settings.appearance

local user = os.getenv("USER") or "kenrictee"
local aerospace = "/etc/profiles/per-user/" .. user .. "/bin/aerospace"
local app_font = settings.font.app .. ":Regular:" .. settings.font.size.app

Sbar.add("event", "focused_window_change")

local left_cap = Frame.add_cap("front_app", "center", "focus", "left")
local front_app = Sbar.add("item", "front_app", {
  position = "center",
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = icon_map["Default"],
    font = app_font,
    color = colors.icon,
    padding_left = appearance.spacing.xl,
    padding_right = appearance.spacing.lg,
  },
  label = {
    string = "Waiting for focus…",
    color = colors.label,
    max_chars = appearance.front_app.max_chars,
    padding_right = appearance.spacing.xl,
  },
  background = {
    drawing = false,
  },
  updates = true,
})

local function trim(text)
  return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function truncate_title(text)
  local max_chars = appearance.front_app.max_chars
  local suffix = appearance.front_app.truncation_suffix
  local length = utf8.len(text)

  if not length then
    if #text <= max_chars then
      return text
    end
    return text:sub(1, max_chars - #suffix) .. suffix
  end

  if length <= max_chars then
    return text
  end

  local suffix_length = utf8.len(suffix) or #suffix
  local keep_chars = math.max(0, max_chars - suffix_length)
  local byte_end = utf8.offset(text, keep_chars + 1)

  if not byte_end then
    return suffix
  end

  return text:sub(1, byte_end - 1) .. suffix
end

local function update_front_app()
  Sbar.exec(aerospace .. " list-windows --focused --format '%{app-name}|%{window-title}'", function(result)
    local app, title = result:match("([^|]*)|(.*)")

    app = trim(app)
    title = trim(title)

    if app == "" then
      app = "Finder"
    end

    if title == "" then
      title = app
    end

    local icon = icon_map[app] or icon_map["Default"]

    front_app:set({
      icon = { string = icon, color = colors.icon },
      label = {
        string = truncate_title(title),
        color = colors.label,
      },
    })
  end)
end

front_app:subscribe({ "routine", "system_woke", "front_app_switched", "focused_window_change" }, update_front_app)

local right_cap = Frame.add_cap("front_app", "center", "focus", "right")
Frame.add_bracket("front_app", { left_cap.name, front_app.name, right_cap.name }, colors)

update_front_app()
