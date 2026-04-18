{
  flake.nixosModules.theming = {
    catppuccin = {
      enable = true;
      flavor = "mocha";
      accent = "flamingo";
    };
  };
}
