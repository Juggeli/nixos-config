{ pkgs, lib, ... }:

pkgs.fetchFromGitHub {
  owner = "AstroNvim";
  repo = "AstroNvim";
  rev = "v3.8.0";
  sha256 = "sha256-qF6FTH3ELuZaJFtFLvcjbpl5sDEBmxUcJswQLIiPsQg=";
}

