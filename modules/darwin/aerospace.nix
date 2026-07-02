{
  flake.darwinModules.aerospace =
    { pkgs, ... }:
    let
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
        "app.zen-browser.zen")
          switch_to_finnish
          ;;
        "md.obsidian")
          switch_to_finnish
          ;;
        "com.microsoft.teams2")
          switch_to_finnish
          ;;
        *)
          switch_to_us
          ;;
        esac
      '';
    in
    {
      homebrew.casks = [ "nikitabobko/tap/aerospace" ];
      environment.systemPackages = [ change-kb-layout ];
      home-manager.users.juggeli.xdg.configFile."aerospace/aerospace.toml".source = ./_aerospace.toml;
    };
}
