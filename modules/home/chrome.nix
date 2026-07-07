{
  flake.homeModules.chrome =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = with pkgs; [
        (ungoogled-chromium.override {
          commandLineArgs = [
            "--enable-features=WebUIDarkMode"
            "--force-dark-mode"
          ];
        })
      ];
    };
}
