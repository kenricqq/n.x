local Colors = require("colors")
local palette = Colors.sections

Sbar.add("event", "send_message")
Sbar.add("event", "hide_message")

local base_font = "MonoLisa:Bold:14.00"
local small_font = "MonoLisa:Bold:7.00"
local message_y_offset = -1
local message_id = 0

local notification = Sbar.add("item", "notifications", {
  position = "center",
  drawing = true,
  icon = { drawing = false },
  label = {
    drawing = false,
    align = "center",
    color = palette.focused_window.icon_active,
    font = base_font,
    padding_left = 10,
    padding_right = 10,
  },
  background = {
    drawing = false,
    color = Colors.with_alpha(palette.apple, 0.16),
    border_color = palette.apple,
    border_width = 2,
  },
  y_offset = message_y_offset,
})

local function hide_notification()
  message_id = message_id + 1
  notification:set({
    label = {
      drawing = false,
      string = "",
      font = small_font,
    },
    background = {
      drawing = false,
    },
  })
  Sbar.set("front_app", { drawing = true })
end

local function show_notification(content, hold)
  message_id = message_id + 1
  local current_message_id = message_id

  notification:set({
    y_offset = message_y_offset,
    label = {
      drawing = true,
      string = content,
      font = small_font,
    },
    background = {
      drawing = true,
    },
  })
  Sbar.set("front_app", { drawing = false })

  Sbar.animate("circ", 18, function()
    notification:set({
      label = { font = base_font },
    })
  end)

  if hold == false then
    Sbar.delay(5, function()
      if current_message_id ~= message_id then
        return
      end
      hide_notification()
    end)
  end
end

notification:subscribe("send_message", function(env)
  local content = env.MESSAGE
  local hold = env.HOLD ~= nil and env.HOLD == "true" or false
  show_notification(content, hold)
end)

notification:subscribe("hide_message", hide_notification)
