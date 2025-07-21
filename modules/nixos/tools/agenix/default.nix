{
  options,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.tools.agenix;
  user = config.plusultra.user;
  secretsDir = ../../../../systems/x86_64-linux + "/${config.networking.hostName}/secrets";
  secretsFile = secretsDir + "/secrets.nix";
in
{
  imports = [ ];
  options.plusultra.tools.agenix = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure agenix.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.agenix.packages."${system}".default
    ];

    age = {
      secrets =
        if pathExists secretsFile then
          mapAttrs' (
            n: _:
            nameValuePair (removeSuffix ".age" n) {
              file = secretsDir + "/${n}";
              owner = mkDefault user.name;
            }
          ) (import secretsFile)
        else
          { };
      identityPaths =
        options.age.identityPaths.default
        ++ (filter pathExists [
          "${config.users.users.${user.name}.home}/.ssh/id_ed25519"
        ]);
    };
  };
}
