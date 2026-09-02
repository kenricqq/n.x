local icons = require("icons")
local colors = require("colors").sections.calendar
local frame_colors = require("colors").sections.telemetry
local settings = require("settings")
local appearance = settings.appearance
local click_script = "open -a 'Calendar'"

local cal = Sbar.add("item", "calendar", {
  padding_left = appearance.item.gap,
  padding_right = 0,
  icon = {
    color = colors.icon,
    padding_left = appearance.spacing.xl,
    padding_right = appearance.spacing.xl,
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
    },
  },
  label = {
    color = colors.label,
    align = "left",
    padding_right = appearance.spacing.xl,
  },
  position = "right",
  update_freq = 30,
  click_script = click_script,
  background = {
    drawing = true,
    color = frame_colors.bg,
    border_color = frame_colors.border,
    border_width = appearance.item.border_width,
  },
})

-- english date
cal:subscribe({ "forced", "routine", "system_woke" }, function()
  local time = os.date("%I:%M %p"):gsub("^0", "")
  cal:set({
    icon = time,
    label = icons.calendar,
  })
end)
