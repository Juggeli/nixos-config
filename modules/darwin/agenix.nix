{
  flake.darwinModules.agenix =
    {
      options,
      pkgs,
      inputs,
      ...
    }:
    {
      environment.systemPackages = [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      # Not filtered by pathExists: under pure flake eval that always returns
      # false for paths outside the store, which would drop the only identity
      # that can actually decrypt (macOS has no /etc/ssh host keys by default).
      age.identityPaths = options.age.identityPaths.default ++ [
        "/Users/juggeli/.ssh/id_ed25519"
      ];
    };
}
