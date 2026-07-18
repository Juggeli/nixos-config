{
  flake.homeModules.devtools =
    { pkgs, lib, ... }:
    let
      # Prebuilt native npm modules (e.g. sharp) dlopen libstdc++, which the
      # nix loader can't resolve; scope the library path to bun processes
      # instead of the whole session so nothing else picks it up.
      bun' =
        if pkgs.stdenv.hostPlatform.isLinux then
          pkgs.symlinkJoin {
            name = "bun-with-libstdcxx";
            paths = [ pkgs.bun ];
            nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
            postBuild = ''
              wrapProgram $out/bin/bun \
                --inherit-argv0 \
                --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}
            '';
          }
        else
          pkgs.bun;
    in
    {
      home-manager.users.juggeli.home.packages =
        with pkgs;
        [
          nodejs
          typescript
          biome
          oxlint
          python3
          pipx
          uv
          husky
          typescript-go
        ]
        ++ [ bun' ];
    };
}
