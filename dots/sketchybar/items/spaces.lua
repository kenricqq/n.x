local palette = require("colors").sections
local colors = palette.spaces
local icon_map = require("helpers.icon_map")
local settings = require("settings")
local appearance = settings.appearance

local user = os.getenv("USER") or "kenrictee"
local aerospace = "/etc/profiles/per-user/" .. user .. "/bin/aerospace"
local app_font = settings.font.app .. ":Regular:" .. settings.font.size.app
local workspace_order = { "1", "2", "A", "B", "C", "D", "N", "T", "U" }
local spaces = {}
local refresh_events = {
  "aerospace_workspace_change",
  "space_windows_change",
  "change-window-workspace",
  "change-workspace-monitor",
  "focused_window_change",
  "front_app_switched",
}

for _, event in ipairs({
  "aerospace_workspace_change",
  "space_windows_change",
  "change-window-workspace",
  "change-workspace-monitor",
  "focused_window_change",
}) do
  Sbar.add("event", event)
end

local function aerospace_exec(args, callback)
  Sbar.exec(aerospace .. " " .. args, callback)
end

local function trim(text)
  return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function resolve_focus_state(workspace_state, space_name)
  local selected = false
  local visible = false

  for line in workspace_state:gmatch("[^\r\n]+") do
    local workspace, is_focused, is_visible = line:match("([^|]+)|([^|]+)|([^|]+)")
    if workspace == space_name then
      selected = is_focused == "true"
      visible = is_visible == "true"
      break
    end
  end

  local state = {
    selected = selected,
    icon_color = colors.icon.color,
    label_color = colors.label.color,
    frame_colors = colors.frame,
  }

  if selected then
    state.icon_color = colors.icon.highlight
    state.label_color = colors.label.highlight
    state.frame_colors = colors.frame_active
  elseif visible then
    state.icon_color = colors.icon.secondary
    state.label_color = colors.label.secondary
    state.frame_colors = colors.frame_visible
  end

  return state
end

local function build_window_label(windows)
  local icons = {}

  for app in windows:gmatch("[^\r\n]+") do
    local clean_app = trim(app)
    if clean_app ~= "" then
      table.insert(icons, icon_map[clean_app] or icon_map["Default"])
    end
  end

  if #icons == 0 then
    return "-", false
  end

  return table.concat(icons, " "), true
end

local function refresh_focus()
  aerospace_exec("list-workspaces --all --format '%{workspace}|%{workspace-is-focused}|%{workspace-is-visible}'", function(workspace_state)
    for _, space_name in ipairs(workspace_order) do
      local space = spaces[space_name]
      local state = resolve_focus_state(workspace_state, space_name)

      space:set({
        icon = {
          highlight = state.selected,
          color = state.icon_color,
        },
        label = {
          highlight = state.selected,
          color = state.label_color,
        },
        background = {
          color = state.frame_colors.bg,
          border_color = state.frame_colors.border,
        },
      })
    end
  end)
end

local function refresh_windows(space_name)
  aerospace_exec("list-windows --format %{app-name} --workspace " .. space_name, function(windows)
    local label, has_windows = build_window_label(windows)

    spaces[space_name]:set({
      icon = {
        padding_right = has_windows and 0 or appearance.item.workspace_padding,
      },
      label = {
        string = label,
        padding_left = has_windows and appearance.item.workspace_content_gap or 0,
        padding_right = has_windows and appearance.item.workspace_padding or 0,
      },
      drawing = true,
    })
  end)
end

local function refresh_spaces()
  refresh_focus()

  for _, space_name in ipairs(workspace_order) do
    refresh_windows(space_name)
  end
end

for _, space_name in ipairs(workspace_order) do
  local is_first = space_name == workspace_order[1]
  local click_script = aerospace .. " workspace " .. space_name

  spaces[space_name] = Sbar.add("item", "space." .. space_name, {
    position = "left",
    padding_left = is_first and 0 or appearance.item.workspace_gap,
    padding_right = 0,
    icon = {
      string = space_name,
      color = colors.icon.color,
      highlight_color = colors.icon.highlight,
      padding_left = appearance.item.workspace_padding,
      padding_right = appearance.item.workspace_padding,
    },
    label = {
      font = app_font,
      string = "-",
      color = colors.label.color,
      highlight_color = colors.label.highlight,
      y_offset = appearance.item.label_y_offset,
      padding_left = 0,
      padding_right = 0,
    },
    click_script = click_script,
    background = {
      drawing = true,
      color = colors.frame.bg,
      border_color = colors.frame.border,
      border_width = appearance.item.border_width,
    },
    drawing = false,
  })
end

local space_watcher = Sbar.add("item", "aerospace.workspace_watcher", {
  drawing = false,
  updates = true,
})

space_watcher:subscribe(refresh_events, refresh_spaces)
refresh_spaces()
