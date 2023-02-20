{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.user;
in
{
  imports = [ ./fish.nix ];

  options.plusultra.user = with types; {
    name = mkOpt str "juggeli" "The name to use for the user account.";
    fullName = mkOpt str "Jukka Alavesa" "The full name of the user.";
    email = mkOpt str "juggeli@gmail.com" "The email of the user.";
    initialPassword = mkOpt str "password"
      "The initial password to use when the user is first created.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { }
      "Extra options passed to <option>users.users.<name></option>.";
  };

  config = {
    environment.systemPackages = with pkgs; [
      lolcat
    ];

    plusultra.home = {
      file = {
        "Downloads/.keep".text = "";
        "code/.keep".text = "";
      };
    };

    users.users.${cfg.name} = {
      isNormalUser = true;

      inherit (cfg) name initialPassword;

      home = "/home/${cfg.name}";
      group = "users";

      shell = pkgs.fish;

      # Arbitrary user ID to use for the user. Since I only
      # have a single user on my machines this won't ever collide.
      # However, if you add multiple users you'll need to change this
      # so each user has their own unique uid (or leave it out for the
      # system to select).
      uid = 1000;

      extraGroups = [ "wheel" ] ++ cfg.extraGroups;
    } // cfg.extraOptions;
  };
}
