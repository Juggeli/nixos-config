{
  flake.homeModules.lazygit =
    { inputs, pkgs, ... }:
    let
      upstream = (import "${inputs.catppuccin}/default.nix" { inherit pkgs; }).packages.lazygit;
      # Upstream themes still use the deprecated `gui.authorColors` key. Lazygit
      # migrates it on every launch and warns when it cannot write the result
      # back to the read-only store path, so ship already-migrated themes.
      migrated = pkgs.runCommand "${upstream.name}-migrated" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
        cp -r ${upstream} $out
        chmod -R u+w $out
        find $out -name '*.yml' -exec yq -i '
          with(select(.gui.authorColors != null);
            .gui.theme.authorColors = .gui.authorColors | del(.gui.authorColors))
        ' {} \;
      '';
    in
    {
      home-manager.users.juggeli = {
        programs.lazygit = {
          enable = true;
          settings = {
            gui = {
              nerdFontsVersion = "3";
            };
            git.diffRenderers = [
              {
                command = "delta --dark --paging=never";
              }
            ];
          };
        };
        catppuccin.lazygit.enable = true;
        catppuccin.sources.lazygit = migrated;
      };
    };
}
