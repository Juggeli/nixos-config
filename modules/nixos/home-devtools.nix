{
  flake.nixosModules.home-devtools =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = with pkgs; [
        nodejs
        typescript
        bun
        biome
        oxlint
        python3
        pipx
        uv
        husky
        typescript-go
      ];
    };
}
