{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.aerospace;
  change-kb-layout = pkgs.writeShellScriptBin "change-kb-layout" ''
    focused_window_id=$(aerospace list-windows --focused --format "%{app-bundle-id}")

    switch_to_us() {
        keyboardSwitcher select 'U.S.'
    }

    switch_to_finnish() {
        keyboardSwitcher select 'Finnish'
    }

    case "$focused_window_id" in
        "com.tinyspeck.slackmacgap")
            switch_to_finnish
            ;;
        "com.google.Chrome")
            switch_to_finnish
            ;;
        "org.mozilla.firefox")
            switch_to_finnish
            ;;
        "com.apple.mail")
            switch_to_finnish
            ;;
        "com.hnc.Discord")
            switch_to_finnish                              
            ;;
        "org.mozilla.com.zen.browser")
            switch_to_finnish
            ;;
        *)
            # Default layout if the app is not recognized
            switch_to_us
            ;;
    esac
  '';
in
{
  options.plusultra.desktop.aerospace = {
    enable = mkBoolOpt false "Whether to enable aerospace";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      casks = [ "nikitabobko/tap/aerospace" ];
    };
    environment.systemPackages = [ change-kb-layout ];
    plusultra.home.configFile = {
      "aerospace/aerospace.toml".source = ./aerospace.toml;
    };
  };
}
