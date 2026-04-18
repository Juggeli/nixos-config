{
  flake.nixosModules.desktop-electron = {
    home-manager.users.juggeli.xdg.configFile."electron-flags.conf".source = ./_electron-flags.conf;

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
