{
  flake.homeModules.crypto =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = with pkgs; [
        ledger-live-desktop
        ledger-udev-rules
      ];
    };
}
