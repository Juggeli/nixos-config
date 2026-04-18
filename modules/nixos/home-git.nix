{
  flake.nixosModules.home-git = {
    home-manager.users.juggeli = {
      programs.git = {
        enable = true;
        lfs.enable = true;
        settings = {
          user = {
            name = "Jukka Alavesa";
            email = "jukka.alavesa@codemate.com";
          };
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
          safe = {
            directory = "/home/juggeli/src/dotfiles";
          };
        };
        ignores = [ ".nvim.lua" ];
      };
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true;
          dark = true;
        };
      };
      catppuccin.delta.enable = true;
    };
  };
}
