{ lib, ... }:
let
  secretsDir = ./_secrets;
  secretsFile = secretsDir + "/secrets.nix";
  agenixShared = {
    age.secrets = lib.mapAttrs' (
      n: _:
      lib.nameValuePair (lib.removeSuffix ".age" n) {
        file = secretsDir + "/${n}";
        owner = lib.mkDefault "juggeli";
      }
    ) (import secretsFile);
  };
in
{
  flake.nixosModules.agenix-shared = agenixShared;
  flake.darwinModules.agenix-shared = agenixShared;
}
