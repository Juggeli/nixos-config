{
  description = "Python Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            (pkgs.python3.withPackages (python-pkgs: [
              python-pkgs.qbittorrent-api
            ]))
            ruff
            ruff-lsp
            pyright
          ];

          buildInputs = with pkgs; [ ];
        };
      }
    );
}
