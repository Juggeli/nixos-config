{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.vscode;
in {
  options.plusultra.apps.vscode = with types; {
    enable = mkBoolOpt false "Whether or not to enable vscode.";
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;
      extensions = with pkgs.vscode-extensions; [
        golang.go
        github.copilot
        github.github-vscode-theme
      ];
      userSettings = {
        "window.titleBarStyle" = "custom";
        "workbench.colorTheme" = "Github Dark Colorblind (Beta)";
        "editor.fontFamily" = "'Comic Code Ligatures','Droid Sans Mono', 'monospace', monospace";
        "github.copilot.enable" = {
          "*" = true;
          "plaintext" = false;
          "markdown" = true;
          "scminput" = false;
        };
      };
    };
  };
}
