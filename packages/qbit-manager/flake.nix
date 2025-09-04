{
  description = "qBittorrent Manager - Automated torrent management tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        qbit-manager = pkgs.callPackage ./default.nix { };
      in
      {
        packages = {
          default = qbit-manager;
          qbit-manager = qbit-manager;
        };

        apps = {
          default = {
            type = "app";
            program = "${qbit-manager}/bin/qbit-manager";
          };
          qbit-manager = {
            type = "app";
            program = "${qbit-manager}/bin/qbit-manager";
          };
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            (pkgs.python3.withPackages (python-pkgs: [
              python-pkgs.qbittorrent-api
            ]))
            ruff
            ruff-lsp
            pyright
          ];

          buildInputs = with pkgs; [ qbit-manager ];

          shellHook = ''
            echo "qBittorrent Manager development environment"
            echo "Available commands:"
            echo "  qbit-manager --help    # Run the tool"
            echo "  python main.py --help  # Run from source"
          '';
        };
      }
    );
}
