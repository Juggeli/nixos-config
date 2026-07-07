{ self, ... }:
{
  flake.darwinModules.base = {
    imports = with self.darwinModules; [
      home-manager
      nix-settings
      fonts
      input
      interface
      user
      homebrew
      aerospace
      raycast
      agenix
      agenix-shared
      tailscale
    ];

    programs.fish.enable = true;
    security.pam.services.sudo_local.touchIdAuth = true;
  };
}
