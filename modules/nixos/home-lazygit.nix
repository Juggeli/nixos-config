{
  flake.nixosModules.home-lazygit = {
    home-manager.users.juggeli = {
      programs.lazygit = {
        enable = true;
        settings = {
          gui = {
            nerdFontsVersion = "3";
          };
          git.pagers = [
            {
              pager = "delta --dark --paging=never";
            }
          ];
        };
      };
      catppuccin.lazygit.enable = true;
    };

    environment.persistence."/persist-home" = {
      users.juggeli.files = [
        ".config/lazygit/state.yml"
      ];
    };
  };
}
