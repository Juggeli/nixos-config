{
  flake.nixosModules.agenix =
    {
      config,
      lib,
      options,
      pkgs,
      inputs,
      ...
    }:
    let
      secretsDir = ../hosts + "/${config.networking.hostName}/_secrets";
      secretsFile = secretsDir + "/secrets.nix";
    in
    {
      environment.systemPackages = [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      age = {
        secrets = lib.mapAttrs' (
          n: _:
          lib.nameValuePair (lib.removeSuffix ".age" n) {
            file = secretsDir + "/${n}";
            owner = lib.mkDefault "juggeli";
          }
        ) (import secretsFile);
        identityPaths = [
          "/persist/etc/ssh/ssh_host_ed25519_key"
        ]
        ++ options.age.identityPaths.default
        ++ lib.filter lib.pathExists [
          "/home/juggeli/.ssh/id_ed25519"
        ];
      };
    };
}
