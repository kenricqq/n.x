all:
	@if [ ! -f icon_map.lua ]; then \
		if command -v wget >/dev/null 2>&1; then \
			wget -q https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.47/icon_map.lua -O icon_map.lua; \
		else \
			curl -fsSL https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.47/icon_map.lua -o icon_map.lua; \
		fi; \
	fi
	(cd event_providers && $(MAKE)) >/dev/null
	(cd menus && $(MAKE)) >/dev/null
