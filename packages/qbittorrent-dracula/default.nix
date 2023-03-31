{ pkgs, lib, ... }:

pkgs.fetchFromGitHub {
  owner = "dracula";
  repo = "qbittorrent";
  rev = "a9d64acd1faf2d23f46a98b20eba6640805a0f62";
  sha256 = "";
  name = "qbittorrent-dracula";
}
