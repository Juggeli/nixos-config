{ options, config, pkgs, lib, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.tools.git;
  user = config.plusultra.user;
in
{
  options.plusultra.tools.git = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure git.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ git ];

    plusultra.home.extraOptions = {
      programs.git = {
        enable = true;
        inherit (cfg) userName userEmail;
        lfs = enabled;
        extraConfig = {
          init = { defaultBranch = "main"; };
          pull = { rebase = true; };
          push = { autoSetupRemote = true; };
          core = { whitespace = "trailing-space,space-before-tab"; };
        };
      };
    };
  };
}