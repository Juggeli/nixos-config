{
  flake.nixosModules.home-vscode = {
    home-manager.users.juggeli = {
      programs.vscode.enable = true;
      catppuccin.vscode.profiles.default.enable = false;
    };
  };
}
