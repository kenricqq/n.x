{ inputs, ... }:

{
  imports = [ inputs.nix-plist-manager.homeManagerModules.default ];

  # https://sushydev.github.io/nix-plist-manager/
  # Omitted settings stay unmanaged. Extra options below are examples, not defaults.
  # Upstream clears ByHost overrides for managed preferences during activation.
  programs.nix-plist-manager = {
    enable = true;
    options.applications = {
      systemSettings = {
        accessibility.display.reduceTransparency = true;
        appearance.liquidGlass = 1.0;
        privacyAndSecurity.appleAdvertising.personalizedAds = false;
        spotlight.helpAppleImproveSearch = false;

        appleIntelligenceAndSiri = {
          appleIntelligence = false;
          automaticVisualLookUp = false;
          siri.enable = false;
          chatGpt.useExtension = false;
        };

        desktopAndDock = {
          desktopAndStageManager.clickWallpaperToRevealDesktop = "Only in Stage Manager";

          dock = {
            automaticallyHideAndShowTheDock = {
              enabled = true;
              delay = 0.0;
              duration = 0.2;
            };
            dockPositionOnScreen = "Bottom";
            size = 62;
            magnification.enabled = true;
            minimizeWindowsIntoApplicationIcon = false;
            showSuggestedAndRecentAppsInDock = false;

            # magnification.size = 96;
            # minimizedWindowAnimation = "Scale Effect";
            # animateOpeningApplications = false;
          };

          missionControl = {
            # no reshuffling of spaces
            automaticallyRearrangeSpacesBasedOnMostRecentUse = false;
            displaysHaveSeparateSpaces = true;
          };

          # Disable native tiling if you prefer AeroSpace to handle windows.
          # windows.dragWindowsToLeftOrRightEdgeOfScreenToTile = false;
          # windows.dragWindowsToMenuBarToFillScreen = false;
          # windows.holdOptionKeyWhileDraggingWindowsToTile = false;
          # windows.tiledWindowsHaveMargins = false;
          # hotCorners.topRight.action = "Lock Screen";
        };

        trackpad = {
          scrollAndZoom.naturalScrolling = true;
          # pointAndClick.tapToClick = true;
          # pointAndClick.secondaryClick = "Click or Tap with Two Fingers";
        };

        keyboard = {
          keyboardShortcuts = {
            keyboard.moveFocusToTheDock = "⌥⇧D";
            inputSources = {
              selectThePreviousInputSource = "⌃Space";
              selectNextSourceInInputMenu = "⌃⌥Space";
            };
            spotlight = {
              showSpotlightSearch = "⌥Space";
              showFinderSearchWindow = "⌥⌘Space";
            };
            missionControl = {
              switchToDesktop7 = "⌥7";
              switchToDesktop8 = "⌥8";
            };
            accessibility = {
              invertColors = false;
              increaseContrast = false;
              decreaseContrast = false;
              showAccessibilityControls = "⌥⌘F5";
            };
          };

          # Key repeat changes take effect after logging out.
          # keyRepeatRate = 2;
          # delayUntilRepeat = 15;
          # useF1F2EtcKeysAsStandardFunctionKeys = true;
          # textInput.correctSpellingAutomatically = false;
          # textInput.capitalizeWordsAutomatically = false;
          # textInput.addPeriodWithDoubleSpace = false;
          # textInput.useSmartQuotesAndDashes = false;
        };

        # appearance.appearance = "Dark";
        # appearance.accentColor = "Graphite";
        # displays.trueTone = false;
        # displays.nightShift.schedule = "Sunset to Sunrise";
        # displays.showResolutionsAsList = true;
        # menuBar.clock.style = "Digital";
        # menuBar.clock.displayTheTimeWithSeconds = true;
        # menuBar.batteryOptions.showPercentage = true;
      };

      finder = {
        menuBar.view = {
          showPathBar = true;
          showStatusBar = true;
        };
        settings = {
          general.showTheseItemsOnTheDesktop = {
            # keep external visible, hide noisy stuff
            externalDisks = true;
            hardDisks = false;
            connectedServers = false;
            cdsDvdsAndiPods = true;
          };
          advanced = {
            showAllFilenameExtensions = true;
            whenPerformingASearch = "Search the Current Folder";
            showWarningBeforeChangingAnExtension = false;
            # file sorting
            keepFoldersOnTop.inWindowsWhenSortingByName = true;
            keepFoldersOnTop.onDesktop = true;
            # delete items in trash after 30 days
            removeItemsFromTheTrashAfter30Days = true;
          };
          # general.openFoldersInTabsInsteadOfNewWindows = true;
          # sidebar.recentTags = false;
        };
      };
    };
  };
}
