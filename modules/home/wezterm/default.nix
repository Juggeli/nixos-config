{
  flake.homeModules.wezterm =
    { pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [ pkgs.wezterm ];
        xdg.configFile."wezterm/wezterm.lua".text = import ./_assets/wezterm.lua { fontSize = "13"; };
      };
    };
}
