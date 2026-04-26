{
  flake.nixosModules.agenix-shared =
    { lib, ... }:
    let
      secretsDir = ./_secrets;
      secretsFile = secretsDir + "/secrets.nix";
    in
    {
      age.secrets = lib.mapAttrs' (
        n: _:
        lib.nameValuePair (lib.removeSuffix ".age" n) {
          file = secretsDir + "/${n}";
          owner = lib.mkDefault "juggeli";
        }
      ) (import secretsFile);
    };
}
