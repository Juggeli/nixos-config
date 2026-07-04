{
  flake.nixosModules.desktop-rofi =
    { lib, pkgs, ... }:
    {
      home-manager.users.juggeli.programs.rofi = {
        enable = true;
        package = pkgs.rofi;
        theme = lib.mkForce ./_theme.rasi;
        terminal = "kitty";
        plugins = with pkgs; [
          rofi-power-menu
          rofi-calc
        ];
        extraConfig = {
          modi = "drun,run,combi,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
          combi-modi = "drun,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
          combi-hide-mode-prefix = true;
          show-icons = true;
        };
      };
    };
}
