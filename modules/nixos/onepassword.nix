{
  flake.nixosModules.onepassword = {
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "juggeli" ];
      };
    };
  };
}
