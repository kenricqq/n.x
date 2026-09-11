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
        else
          throw "lg-input: unsupported platform ${machine.system}"
      }
    '';
  };

  lapMode = pkgs.writeShellApplication {
    name = "lap-mode";

    text = ''
      usage() {
        echo 'usage: lap-mode mirror [lap|lg] | lap-mode extend' >&2
        exit 1
      }
      (( $# >= 1 && $# <= 2 )) || usage

      # BetterDisplay must be running. The target mirrors the source.
      case "$1" in
        mirror)
          case "''${2-lap}" in
            lap) source="Built-in"; target=LG ;;
            lg) source=LG; target="Built-in" ;;
            *) usage ;;
          esac
          exec "${betterDisplay}" set \
            --namelike="$source" \
            --targetNameLike="$target" \
            --mirror=on
          ;;
        extend)
          (( $# == 1 )) || usage
          exec "${betterDisplay}" set \
            --namelike=LG \
            --mirror=off
          ;;
        *) usage ;;
      esac
    '';
  };
in
{
  home.packages =
    lib.optionals host.isLinux [
      lgInput
    ]
    ++ lib.optionals host.isDarwin [
      pkgs.betterdisplay
      lapMode
    ];

  programs.nushell.extraConfig =
    lib.optionalString host.isLinux ''
      def "nu-complete lg-input" [] { [ dp hdmi1 hdmi2 ] }
      extern "lg-input" [input: string@"nu-complete lg-input"]
    ''
    + lib.optionalString host.isDarwin ''
      def "nu-complete lap-mode" [] { [ mirror extend ] }
      def "nu-complete lap-mode-display" [] { [ lap lg ] }
      extern "lap-mode" [mode: string@"nu-complete lap-mode", display?: string@"nu-complete lap-mode-display"]
    '';
}
