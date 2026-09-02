local Colors = {}

Colors.with_alpha = function(color, alpha)
  if alpha > 1.0 or alpha < 0.0 then
    return color
  end
  return (color & 0x00FFFFFF) | (math.floor(alpha * 255.0) << 24)
end

local a = Colors.with_alpha

Colors.palette = {
  bg = 0xFF070403,
  panel = 0xFF100806,
  panel_alt = 0xFF241009,
  text = 0xFFFFF0E6,
  text_muted = 0xFFB8A097,
  accent = 0xFFFF6800,
  accent_alt = 0xFFFF3020,
  warm = 0xFFFF8B24,
  danger = 0xFFFF3020,
}

local p = Colors.palette
local surface = {
  bar = a(p.bg, 0.97),
  item = p.panel,
  item_active = p.panel_alt,
  popup = a(p.bg, 0.98),
}
local line = {
  subtle = a(p.accent, 0.16),
  default = a(p.accent, 0.34),
  context = a(p.accent, 0.68),
  focus = a(p.accent, 0.92),
}
local text = {
  primary = a(p.text, 0.98),
  secondary = a(p.text, 0.88),
  muted = a(p.text_muted, 0.82),
  accent = a(p.warm, 0.96),
}

Colors.sections = {
  bar = {
    bg = surface.bar,
    border = a(p.accent, 0.32),
  },
  item = {
    bg = surface.item,
    bg_active = surface.item_active,
    border = line.subtle,
    border_active = line.focus,
    text = text.primary,
    text_muted = text.muted,
  },
  popup = {
    bg = surface.popup,
    border = line.default,
  },

  apple = a(p.danger, 0.72),
  media = { label = text.secondary },
  calendar = {
    icon = text.primary,
    label = text.accent,
  },
  focused_window = {
    bg = p.panel_alt,
    border = line.context,
    icon = a(p.accent, 0.90),
    icon_active = text.accent,
    label = text.primary,
    label_active = text.primary,
  },
  status = {
    bg = a(p.warm, 0.16),
    border = a(p.warm, 0.34),
    label = a(p.warm, 0.92),
  },
  spaces = {
    frame = {
      bg = p.panel,
      border = line.subtle,
    },
    frame_visible = {
      bg = a(p.danger, 0.08),
      border = a(p.danger, 0.76),
    },
    frame_active = {
      bg = p.panel_alt,
      border = line.focus,
    },
    icon = {
      color = a(p.text_muted, 0.86),
      highlight = text.accent,
      secondary = a(p.accent_alt, 0.90),
    },
    label = {
      color = a(p.text_muted, 0.82),
      highlight = text.primary,
      secondary = text.muted,
    },
    indicator = a(p.warm, 0.96),
  },
  widgets = {
    battery = {
      low = a(p.danger, 0.78),
      mid = a(p.warm, 0.74),
      high = a(p.accent_alt, 0.74),
    },
    cpu = {
      icon = text.accent,
      normal = text.secondary,
      warn = a(p.warm, 0.74),
      critical = a(p.danger, 0.78),
      graph = a(p.accent, 0.68),
      fill = a(p.accent, 0.12),
      warn_graph = a(p.warm, 0.68),
      warn_fill = a(p.warm, 0.12),
      critical_graph = a(p.danger, 0.70),
      critical_fill = a(p.danger, 0.12),
      bg = surface.item,
      border = line.focus,
    },
    ram = {
      icon = text.accent,
      normal = text.secondary,
      warn = a(p.warm, 0.74),
      critical = a(p.danger, 0.78),
      graph = a(p.accent, 0.66),
      fill = a(p.accent, 0.10),
      warn_graph = a(p.warm, 0.68),
      warn_fill = a(p.warm, 0.10),
      critical_graph = a(p.danger, 0.70),
      critical_fill = a(p.danger, 0.10),
      bg = surface.item,
      border = line.focus,
    },
    group = {
      bg = a(p.bg, 0.18),
      border = line.subtle,
    },
    wifi = {
      icon = a(p.accent, 0.88),
      active = a(p.danger, 0.96),
    },
    volume = {
      icon = text.accent,
      bg1 = line.subtle,
      popup = {
        item = text.secondary,
        highlight = a(p.warm, 0.76),
        bg = surface.popup,
      },
      slider = {
        highlight = text.secondary,
        border = line.default,
        bg = surface.popup,
      },
    },
    messages = { icon = a(p.danger, 0.72) },
  },
  telemetry = {
    bg = p.panel,
    border = line.default,
  },
}

return Colors
