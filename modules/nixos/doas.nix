{
  flake.nixosModules.doas = {
    security.sudo.enable = false;

    security.doas = {
      enable = true;
      extraRules = [
        {
          users = [ "juggeli" ];
          noPass = true;
          keepEnv = true;
        }
      ];
    };

    environment.shellAliases.sudo = "doas";
  };
}
