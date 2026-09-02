local settings = require("settings")

local Frame = {}
local appearance = settings.appearance
local source = debug.getinfo(1, "S").source:sub(2)
local helper_dir = source:match("(.*/)") or "./"
local asset_dir = helper_dir .. "../assets/"

local function asset_path(variant, side)
  return asset_dir .. "frame-" .. variant .. "-" .. side .. ".png"
end

function Frame.add_cap(name, position, variant, side)
  return Sbar.add("item", name .. ".frame." .. side, {
    position = position,
    width = appearance.frame.cap_width,
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = { drawing = false },
    background = {
      drawing = true,
      color = 0x00000000,
      border_width = 0,
      height = appearance.item.height,
      corner_radius = 0,
      image = {
        drawing = true,
        string = asset_path(variant, side),
        scale = appearance.frame.image_scale,
        corner_radius = 0,
      },
    },
  })
end

function Frame.add_bracket(name, members, colors)
  return Sbar.add("bracket", name .. ".frame", members, {
    background = {
      color = colors.bg,
      border_color = colors.border,
      border_width = appearance.item.border_width,
      height = appearance.item.height,
      corner_radius = 0,
    },
  })
end

function Frame.set_drawing(name, drawing)
  for _, item_name in ipairs({
    name,
    name .. ".frame",
    name .. ".frame.left",
    name .. ".frame.right",
  }) do
    Sbar.set(item_name, { drawing = drawing })
  end
end

return Frame
