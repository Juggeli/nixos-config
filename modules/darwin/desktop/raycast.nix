{
  lib,
  config,
  ...
}:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.raycast;
in
{
  options.plusultra.desktop.raycast = {
    enable = mkBoolOpt false "Whether to enable raycast";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      casks = [ "raycast" ];
    };

    launchd.user.agents.raycast.serviceConfig = {
      Disabled = false;
      ProgramArguments = [
        "/Applications/Raycast.app/Contents/Library/LoginItems/RaycastLauncher.app/Contents/MacOS/RaycastLauncher"
      ];
      RunAtLoad = true;
    };
  };
}
