{ pkgs, lib, ... }:

pkgs.fetchzip {
  url = "https://github.com/WDaan/VueTorrent/releases/download/v1.5.3/vuetorrent.zip";
  sha256 = "sha256-sq7OlFYKh54NXOFoF+zWmSZLf26978OOEH1+qRcU6aw=";
  name = "vuetorrent";
}
