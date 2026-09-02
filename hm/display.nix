{
  host,
  machine,
  pkgs,
  lib,
  ...
}:

let
  betterDisplay = "${pkgs.betterdisplay}/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay";

  lgInput = pkgs.writeShellApplication {
    name = "lg-input";

    text = ''
      case "''${1:-}" in
        dp)    input="D0" ;;
        hdmi1) input="90" ;;
        hdmi2) input="91" ;;
        *)
          echo "usage: lg-input {dp|hdmi1|hdmi2}" >&2
          exit 1
          ;;
      esac

      ${
        if host.isLinux then
          ''
            exec ddcutil \
              -d "''${DDC_DISPLAY:-1}" \
              setvcp xF4 "x00$input" \
              --i2c-source-addr=x50 \
              --noverify
          ''
        else if host.isDarwin then
          ''
            exec "${betterDisplay}" set \
              --namelike=LG \
              --ddcAlt="0x$input" \
              --vcp=inputSelectAlt
          ''
        else
          throw "lg-input: unsupported platform ${machine.system}"
      }
    '';
  };

  lgMode = pkgs.writeShellApplication {
    name = "lg-mode";

    text = ''
      if (( $# < 2 || $# > 3 )); then
        echo 'usage: lg-mode {mirror|extend} SOURCE_NAME [TARGET_NAME_LIKE=LG]' >&2
        exit 1
      fi

      case "$1" in
        mirror) mirror=on ;;
        extend) mirror=off ;;
        *) echo "unknown display mode: $1" >&2; exit 1 ;;
      esac

      # BetterDisplay must be running. The target mirrors the source display.
      exec "${betterDisplay}" set \
        --name="$2" \
        --targetNameLike="''${3:-LG}" \
        --mirror="$mirror"
    '';
  };
in
{
  home.packages = [
    lgInput
  ]
  ++ lib.optionals host.isDarwin [
    pkgs.betterdisplay
    lgMode
  ];

  programs.nushell.extraConfig = ''
    def "nu-complete lg-input" [] { [ dp hdmi1 hdmi2 ] }
    extern "lg-input" [input: string@"nu-complete lg-input"]
  ''
  + lib.optionalString host.isDarwin ''
    def "nu-complete display-mode" [] { [ mirror extend ] }
    extern "display-mode" [mode: string@"nu-complete display-mode", source: string, target?: string]
  '';
}
