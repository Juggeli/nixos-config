{ self, ... }:
{
  flake.darwinConfigurations.kuro = self.lib.mkDarwin {
    hostName = "kuro";
    modules =
      (with self.darwinModules; [ base ])
      ++ (with self.homeModules; [
        desktop
        syncthing
      ])
      ++ [
        { system.stateVersion = 6; }
      ];
  };
}
