{ config, pkgs, ... }:

{
  programs.pi-coding-agent = {
    enable = true;
    configDir = "${config.xdg.configHome}/pi/agent";

    # context = ./pi-context.md # default: ~/.pi/agent/AGENTS.md
    extraPackages = with pkgs; [
      nodejs
      bun
    ];
    # keybindings = {
    #   "tui.editor.cursorDown" = [
    #     "down"
    #     "ctrl+n"
    #   ];
    #   "tui.editor.cursorUp" = [
    #     "up"
    #     "ctrl+p"
    #   ];
    #   "tui.editor.deleteWordBackward" = [
    #     "ctrl+w"
    #     "alt+backspace"
    #   ];
    # };
    # settings = {
    #   compaction = {
    #     enabled = true;
    #     keepRecentTokens = 20000;
    #     reserveTokens = 16384;
    #   };
    #   defaultModel = "gpt-5.6-sol";
    #   defaultProvider = "openai-codex";
    #   defaultThinkingLevel = "xhigh";
    #   enabledModels = [
    #     "claude-*"
    #     "gpt-4o"
    #   ];
    #   # packages = [
    #   #   "npm:@termdraw/pi"
    #   #   "npm:pi-mcp-adapter"
    #   # ];
    #   retry = {
    #     enabled = true;
    #     maxRetries = 3;
    #   };
    #   theme = "dark";
    # };
  };
}
