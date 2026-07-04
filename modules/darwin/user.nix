{
  flake.darwinModules.user = {
    users.users.juggeli = {
      uid = 501;
      home = "/Users/juggeli";
    };

    home-manager.users.juggeli.home.file.".profile".text = ''
      # The default file limit is far too low and throws an error when rebuilding the system.
      # See the original with: ulimit -Sa
      ulimit -n 4096
    '';
  };
}
