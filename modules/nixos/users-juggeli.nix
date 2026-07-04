{
  flake.nixosModules.users-juggeli =
    { pkgs, ... }:
    {
      programs.fish.enable = true;

      users.mutableUsers = false;
      users.users.root.initialHashedPassword = "$y$j9T$vlxeZP0tYFe8ijF9gE40p0$zbi/GzShWgo.c292Zd.F3lVcxozCaq.iQjxjpaEcF07";

      users.users.juggeli = {
        isNormalUser = true;
        home = "/home/juggeli";
        group = "users";
        shell = pkgs.fish;
        uid = 1000;
        initialHashedPassword = "$y$j9T$vlxeZP0tYFe8ijF9gE40p0$zbi/GzShWgo.c292Zd.F3lVcxozCaq.iQjxjpaEcF07";
        extraGroups = [
          "wheel"
          "media"
        ];
      };
    };
}
