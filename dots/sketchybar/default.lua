local settings = require("settings")
local appearance = settings.appearance
local colors = require("colors").sections

Sbar.default({
  updates = "when_shown",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = settings.font.size.base,
    },
    color = colors.item.text,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    background = { image = { corner_radius = appearance.item.radius } },
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = settings.font.size.base,
    },
    color = colors.item.text,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  background = {
    height = appearance.item.height,
    corner_radius = appearance.item.radius,
    color = colors.item.bg,
    border_color = colors.item.border,
    border_width = appearance.item.border_width,
  },
  popup = {
    background = {
      color = colors.popup.bg,
      border_color = colors.popup.border,
      border_width = appearance.popup.border_width,
      corner_radius = appearance.popup.radius,
      shadow = {
        drawing = false,
        angle = 45,
        distance = 4,
        color = colors.item.border,
      },
    },
  },
  padding_left = settings.paddings,
  padding_right = settings.paddings,
  scroll_texts = false,
})
