local icons = require("icons")
local colors = require("colors").sections.widgets.wifi
local frame_colors = require("colors").sections.telemetry
local appearance = require("settings").appearance

local popup_width = appearance.popup.width

local wifi = Sbar.add("item", "wifi", {
  position = "right",
  padding_left = 0,
  padding_right = 0,
  icon = {
    color = colors.icon,
    padding_left = appearance.spacing.xl,
  },
  label = {
    padding_right = appearance.spacing.xl,
  },
  popup = {
    align = "center",
    height = appearance.popup.height,
    y_offset = appearance.popup.y_offset,
  },
  background = {
    drawing = true,
    color = frame_colors.bg,
    border_color = frame_colors.border,
    border_width = appearance.item.border_width,
  },
})

local ip = Sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "IP:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
  background = { drawing = false },
})

local router = Sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "Router:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
  background = { drawing = false },
})

wifi:subscribe({ "wifi_change", "system_woke", "forced" }, function()
  Sbar.exec(
    "networksetup -listpreferredwirelessnetworks en0 | sed -n '2p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'",
    function(result)
      local ssid = result:gsub("\n", "")
      local is_connected = not (ssid == "")

      if not is_connected then
        ssid = "Not connected"
      end

      wifi:set({
        icon = {
          string = is_connected and icons.wifi.connected or icons.wifi.disconnected,
          color = colors.icon,
        },
        label = {
          string = is_connected and ssid or "",
        },
      })

      Sbar.exec([[sleep 2; scutil --nwi | grep -m1 'utun' | awk '{ print $1 }']], function(vpn)
        local is_vpn_connected = not (vpn == "")

        if is_vpn_connected then
          wifi:set({
            icon = {
              string = icons.wifi.vpn,
              color = colors.active,
            },
          })
        end
      end)
    end
  )
end)

local function hide_details()
  wifi:set({ popup = { drawing = false } })
end

local function toggle_details()
  local should_draw = wifi:query().popup.drawing == "off"
  if should_draw then
    wifi:set({ popup = { drawing = true } })
    Sbar.exec("ipconfig getifaddr en0", function(result)
      ip:set({ label = result })
    end)
    Sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
      router:set({ label = result })
    end)
  else
    hide_details()
  end
end

wifi:subscribe("mouse.clicked", toggle_details)

-- wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
  local label = Sbar.query(env.NAME).label.value
  Sbar.exec('echo "' .. label .. '" | pbcopy')
  Sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
  Sbar.delay(1, function()
    Sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

ip:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
