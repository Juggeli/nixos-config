{
  flake.darwinModules.agenix =
    {
      lib,
      options,
      pkgs,
      inputs,
      ...
    }:
    {
      environment.systemPackages = [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      age.identityPaths =
        options.age.identityPaths.default
        ++ lib.filter lib.pathExists [
          "/Users/juggeli/.ssh/id_ed25519"
        ];
    };
}
