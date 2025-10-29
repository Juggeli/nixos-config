{
  description = "Sorter - Interactive Media File Organizer";

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

            pkg-config
            gcc

            ffmpeg
            mpv

            xorg.libX11
            xorg.libXcursor
            xorg.libXrandr
            xorg.libXinerama
            xorg.libXi
            xorg.libXxf86vm
            libGL
            libGLU
          ];

          shellHook = ''
            echo "Go development environment loaded"
            echo "Go version: $(go version)"
            echo ""
            echo "Available commands:"
            echo "  go build -o sorter    # Build the application"
            echo "  go run .              # Run the application (TUI mode)"
            echo "  go run . --gui        # Run the application (GUI mode)"
            echo "  go mod tidy           # Update dependencies"
            echo "  ./sorter --help       # Show application help"
          '';
        };

        packages.default = pkgs.buildGoModule {
          pname = "sorter";
          version = "1.0.0";
          src = ./.;
          vendorHash = "sha256-kVrz8FYO/2lkW1oVG8bmA2J+8aHqx/YFpIpi25QTw2I=";

          nativeBuildInputs = with pkgs; [
            pkg-config
            gcc
          ];

          buildInputs = with pkgs; [
            ffmpeg
            mpv
            xorg.libX11
            xorg.libXcursor
            xorg.libXrandr
            xorg.libXinerama
            xorg.libXi
            xorg.libXxf86vm
            libGL
            libGLU
          ];

          meta = with pkgs.lib; {
            description = "Interactive TUI/GUI media file organizer";
            homepage = "https://github.com/plusultra/sorter";
            license = licenses.mit;
            maintainers = [ maintainers.plusultra ];
          };
        };
      }
    );
}
