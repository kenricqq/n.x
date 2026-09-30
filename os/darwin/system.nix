{
  # Preferences without an exact nix-plist-manager equivalent stay here.
  # Other user settings live in hm/macos/system-settings.nix.
  defaults = {
    CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        # Preserve custom Mission Control keys, disabled keys' saved bindings,
        # and legacy IDs that nix-plist-manager cannot express unchanged.
        AppleSymbolicHotKeys = {
          "15" = {
            enabled = false;
          };
          "16" = {
            enabled = false;
          };
          "17" = {
            enabled = false;
          };
          "18" = {
            enabled = false;
          };
          "19" = {
            enabled = false;
          };
          "20" = {
            enabled = false;
          };
          "22" = {
            enabled = false;
          };
          "23" = {
            enabled = false;
          };
          "24" = {
            enabled = false;
          };
          "32" = {
            enabled = true;
            value = {
              parameters = [
                107
                40
                655360
              ];
              type = "standard";
            };
          };
          "33" = {
            enabled = true;
            value = {
              parameters = [
                106
                38
                655360
              ];
              type = "standard";
            };
          };
          "34" = {
            enabled = false;
            value = {
              parameters = [
                107
                40
                655360
              ];
              type = "standard";
            };
          };
          "35" = {
            enabled = false;
            value = {
              parameters = [
                106
                38
                655360
              ];
              type = "standard";
            };
          };
          "36" = {
            enabled = true;
            value = {
              parameters = [
                65535
                103
                8388608
              ];
              type = "standard";
            };
          };
          "37" = {
            enabled = true;
            value = {
              parameters = [
                65535
                103
                8519680
              ];
              type = "standard";
            };
          };
          "79" = {
            enabled = false;
            value = {
              parameters = [
                104
                4
                524288
              ];
              type = "standard";
            };
          };
          "80" = {
            enabled = true;
            value = {
              parameters = [
                104
                4
                655360
              ];
              type = "standard";
            };
          };
          "81" = {
            enabled = false;
            value = {
              parameters = [
                108
                37
                524288
              ];
              type = "standard";
            };
          };
          "82" = {
            enabled = true;
            value = {
              parameters = [
                108
                37
                655360
              ];
              type = "standard";
            };
          };
          "118" = {
            enabled = false;
            value = {
              parameters = [
                49
                18
                524288
              ];
              type = "standard";
            };
          };
          "119" = {
            enabled = false;
            value = {
              parameters = [
                50
                19
                524288
              ];
              type = "standard";
            };
          };
          "120" = {
            enabled = false;
            value = {
              parameters = [
                51
                20
                524288
              ];
              type = "standard";
            };
          };
          "121" = {
            enabled = false;
            value = {
              parameters = [
                52
                21
                524288
              ];
              type = "standard";
            };
          };
          "122" = {
            enabled = false;
            value = {
              parameters = [
                53
                23
                524288
              ];
              type = "standard";
            };
          };
          "123" = {
            enabled = false;
            value = {
              parameters = [
                54
                22
                524288
              ];
              type = "standard";
            };
          };
          "160" = {
            enabled = true;
            value = {
              parameters = [
                65535
                65535
                0
              ];
              type = "standard";
            };
          };
          "164" = {
            enabled = false;
            value = {
              parameters = [
                65535
                65535
                0
              ];
              type = "standard";
            };
          };
        };
      };
    };
    dock = {
      expose-animation-duration = 0.1;

      # nix-plist-manager's Dock snapshot also replaces persistent-others.
      persistent-apps = [ ];

      # hot corners
      # wvous-tl-corner = 10;
      # wvous-tr-corner = 12;
      # wvous-bl-corner = 5;
      # wvous-br-corner = 14;

      # Dock settings.
      showhidden = true;
    };
    finder = {
      FXPreferredViewStyle = "Nlsv";

      # Keep the Finder-scoped preference; nix-plist-manager writes NSGlobalDomain.
      AppleShowAllExtensions = true;
    };
    NSGlobalDomain = {
      # The nix-plist-manager menu-bar enum also changes full-screen behavior.
      _HIHideMenuBar = true;
      # _HIHideMenuBar = false;
      # enables cmd+ctrl to move any window
      NSWindowShouldDragOnGesture = true;
    };
  };
  keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
