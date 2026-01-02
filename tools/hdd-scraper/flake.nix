{
  description = "HDD Price Scraper - Fetch and analyze HDD prices from tietokonekauppa.fi";

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
            (python3.withPackages (
              ps: with ps; [
                requests
                beautifulsoup4
                lxml
                tabulate
              ]
            ))
          ];

          shellHook = ''
            echo "HDD Scraper development environment loaded"
            echo ""
            echo "Available commands:"
            echo "  python hdd_scraper.py    # Run the scraper"
            echo "  python -m pytest         # Run tests (if added)"
          '';
        };
      }
    );
}
