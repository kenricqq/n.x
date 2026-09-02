local colors = require("colors").sections.status
local Frame = require("helpers.frame")
local settings = require("settings")
local appearance = settings.appearance

Sbar.add("event", "send_message")
Sbar.add("event", "hide_message")

local message_id = 0

local status = Sbar.add("item", "status", {
  position = "center",
  drawing = true,
  icon = { drawing = false },
  label = {
    drawing = false,
    align = "center",
    color = colors.label,
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = settings.font.size.base,
    },
    padding_left = appearance.spacing.xl,
    padding_right = appearance.spacing.xl,
  },
  background = {
    drawing = false,
    color = colors.bg,
    border_color = colors.border,
    border_width = appearance.item.border_width,
  },
})

local function normalize_message(content)
  if content == "Aerospace in Service Mode" then
    return "AEROSPACE SERVICE"
  end
  return content
end

local function hide_status()
  message_id = message_id + 1
  status:set({
    label = {
      drawing = false,
      string = "",
    },
    background = {
      drawing = false,
    },
  })
  Frame.set_drawing("front_app", true)
end

local function show_status(content, hold)
  message_id = message_id + 1
  local current_message_id = message_id
  local label = normalize_message(content or "")

  status:set({
    label = {
      drawing = label ~= "",
      string = label,
    },
    background = {
      drawing = label ~= "",
    },
  })
  Frame.set_drawing("front_app", false)

  if hold == false then
    Sbar.delay(5, function()
      if current_message_id == message_id then
        hide_status()
      end
    end)
  end
end

status:subscribe("send_message", function(env)
  local hold = env.HOLD ~= nil and env.HOLD == "true" or false
  show_status(env.MESSAGE, hold)
end)

status:subscribe("hide_message", hide_status)
