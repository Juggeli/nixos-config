{
  flake.nixosModules.home-gh = {
    home-manager.users.juggeli = {
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };

      xdg.configFile."gh/config.yml".force = true;
    };
  };
}
