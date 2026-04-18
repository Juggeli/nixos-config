{
  flake.nixosModules.graphical =
    { lib, pkgs, ... }:
    {
      boot.plymouth = {
        enable = true;
        theme = lib.mkForce "lone";
        themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "lone" ]; }) ];
      };
    };
}
