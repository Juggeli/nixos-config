{ lib, config, ... }:

let
  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.plusultra) mkOpt enabled;

  cfg = config.plusultra.tools.git;
  user = config.plusultra.user;
in
{
  options.plusultra.tools.git = {
    enable = mkEnableOption "Git";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      delta = {
        enable = true;
        options = {
          navigate = true;
          dark = true;
        };
      };
      inherit (cfg) userName userEmail;
      lfs = enabled;
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        pull = {
          rebase = true;
        };
        push = {
          autoSetupRemote = true;
        };
        core = {
          whitespace = "trailing-space,space-before-tab";
        };
        merge = {
          conflictstyle = "zdiff3";
        };
      };
      ignores = [ ".nvim.lua" ];
    };
    catppuccin.delta.enable = true;
  };
}
