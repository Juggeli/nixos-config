{ inputs, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.nur.overlays.default
          (final: prev: {
            unstable = import inputs.unstable {
              inherit system;
              config.allowUnfree = true;
            };
          })
        ];
      };
    };
}
