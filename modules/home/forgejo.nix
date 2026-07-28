{
  flake.homeModules.forgejo =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      hmLib = inputs.home-manager.lib;
    in
    {
      home-manager.users.juggeli = {
        home.packages = [ pkgs.forgejo-cli ];

        # The whole keys.json is the secret because fj keeps the token inside
        # a structured file, not in a token-only path it could read at runtime.
        # A writable copy rather than a symlink: fj opens the file read-write
        # even for read-only commands. Local `fj auth` changes therefore last
        # only until the next switch; lasting ones go through the secret.
        home.activation.forgejoKeys = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.local/share/forgejo-cli"
          ${pkgs.coreutils}/bin/install -m 600 \
            ${config.age.secrets.forgejo-fj-keys.path} \
            "$HOME/.local/share/forgejo-cli/keys.json"
        '';
      };
    };
}
