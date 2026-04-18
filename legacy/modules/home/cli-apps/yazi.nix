{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.yazi;
in
{
  options.plusultra.cli-apps.yazi = with types; {
    enable = mkBoolOpt false "Whether or not to enable yazi.";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = false;
      settings = {
        preview = {
          image_delay = 0;
        };
      };
      extraPackages = with pkgs; [
        p7zip
        pigz
        pbzip2
        pixz
        lz4
        zstd
        unrar
      ];
      plugins = {
        archives = pkgs.fetchFromGitHub {
          owner = "maximtrp";
          repo = "archives.yazi";
          rev = "fa8740f8c9360c569693a029c22d309e64d1f3a6";
          hash = "sha256-dW53xjfa6FUyqh+SOSPHBMOm1SqSyBwZGG9zE1aldg4=";
        };
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [
              "c"
              "z"
            ];
            run = "plugin archives -- compress";
            desc = "Compress selection";
          }
          {
            on = [
              "c"
              "x"
            ];
            run = "plugin archives -- extract";
            desc = "Extract archive";
          }
        ];
      };
    };
    catppuccin.yazi.enable = true;
  };
}
