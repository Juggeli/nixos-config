{
  description = "Sorter - Interactive TUI Media File Organizer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            gotools
            go-outline
            gocode-gomod
            gopkgs
            godef
            golint
            delve

            mpv
          ];

          shellHook = ''
            echo "Go development environment loaded"
            echo "Go version: $(go version)"
            echo ""
            echo "Available commands:"
            echo "  go build -o sorter    # Build the application"
            echo "  go run .              # Run the application"
            echo "  go mod tidy           # Update dependencies"
            echo "  ./sorter --help       # Show application help"
          '';
        };

        packages.default = pkgs.buildGoModule {
          pname = "sorter";
          version = "1.0.0";
          src = ./.;
          vendorHash = "sha256-bISowpqJ0zMaX4bmzPu0d7XuZqjdoCe5zPnFKiCGjN4=";

          meta = with pkgs.lib; {
            description = "Interactive TUI media file organizer";
            homepage = "https://github.com/plusultra/sorter";
            license = licenses.mit;
            maintainers = [ maintainers.plusultra ];
          };
        };
      }
    );
}
