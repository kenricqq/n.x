local colors = require("colors").sections.bar
local appearance = require("settings").appearance

Sbar.bar({
  position = appearance.bar.position,
  topmost = "window",
  height = appearance.bar.height,
  notch_display_height = appearance.bar.notch_height,
  padding_right = appearance.spacing.edge,
  padding_left = appearance.spacing.edge,
  margin = appearance.bar.margin,
  corner_radius = appearance.bar.radius,
  y_offset = appearance.bar.y_offset,
  blur_radius = appearance.bar.blur,
  border_color = colors.border,
  border_width = appearance.bar.border_width,
  font_smoothing = appearance.bar.font_smoothing,
  color = colors.bg,
})
