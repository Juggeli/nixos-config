{ options, config, lib, ... }:

with lib;
with lib.plusultra;
{
  options.plusultra.home = with types; {
    file = mkOpt attrs { }
      "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile = mkOpt attrs { }
      "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
    homeConfig = mkOpt attrs { } "Final config for home-manager.";
  };

  config = {
    plusultra.home.extraOptions = {
      home.stateVersion = mkDefault "23.05";
      home.file = mkAliasDefinitions options.plusultra.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.plusultra.home.configFile;
    };

    snowfallorg.user.${config.plusultra.user.name}.home.config = mkAliasDefinitions options.plusultra.home.extraOptions;

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}

