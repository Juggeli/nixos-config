{
  flake.darwinModules.base = {
    programs.fish.enable = true;
    security.pam.services.sudo_local.touchIdAuth = true;
  };
}
