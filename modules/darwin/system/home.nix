{ options, config, lib, ... }:

with lib;
with lib.plusultra;
{
  options.plusultra.home = with types; {
    file = mkOpt attrs { }
      "A set of files to be managed by home-manager's home.file.";
    configFile = mkOpt attrs { }
      "A set of files to be managed by home-manager's xdg.configFile.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
  };

  config = {
    plusultra.home.extraOptions = {
      home.stateVersion = mkDefault "23.11";
      home.file = mkAliasDefinitions options.plusultra.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.plusultra.home.configFile;
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.${config.plusultra.user.name} =
        mkAliasDefinitions options.plusultra.home.extraOptions;
    };
  };
}

