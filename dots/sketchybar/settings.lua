return {
  paddings = 3,
  group_paddings = 4,
  icons = "sf-symbols",
  appearance = {
    bar = {
      position = "top",
      height = 30,
      notch_height = 30,
      margin = 0,
      y_offset = 0,
      blur = 0,
      radius = 50,
      -- border_width = 2,
      font_smoothing = true,
    },
    item = {
      height = 30,
      radius = 50,
      border_width = 1,
      gap = 7,
      workspace_gap = 2,
      workspace_padding = 15,
      workspace_content_gap = 12,
      label_y_offset = 0,
    },
    frame = {
      cap_width = 12,
      image_scale = 0.5,
    },
    popup = {
      width = 250,
      height = 30,
      radius = 2,
      border_width = 1,
      y_offset = 3,
    },
    front_app = {
      max_chars = 30,
      truncation_suffix = "..",
    },
    spacing = {
      sm = 2,
      md = 4,
      lg = 6,
      xl = 9,
      xxl = 15,
      edge = 2,
    },
  },
  font = {
    text = "MonoLisa", -- Used for text
    numbers = "MonoLisa", -- Used for numbers
    weather = "MonoLisa",
    app = "sketchybar-app-font",
    size = {
      base = 13.0,
      app = 14.0,
    },
    style_map = {
      ["Regular"] = "Regular",
      ["Semibold"] = "SemiBold",
      ["Bold"] = "Bold",
      ["Heavy"] = "ExtraBold",
      ["Black"] = "Black",
    },
  },
}
