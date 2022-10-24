{ config, options, inputs, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.generic;
  inherit (inputs) webcord-overlay;
in
{
  options.modules.desktop.generic = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      killall
      pcmanfm
      xdg-utils
      hydrus
      vifm
      webcord-overlay.packages.${pkgs.system}.default
      btop
      obsidian
      go
      (writeShellScriptBin "encode" ''    
shopt -s nullglob
shopt -s globstar
for FILE in ''$1/**/*.{mkv,avi,mp4,m4v,wmv,divx,xvid,mov,flv,f4v,swf,webm,mpeg,mpg}
do
  CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "''${FILE}");
  if [[ $CODEC != "av1" ]]; then
    echo "File ''${FILE} is not av1";
    ab-av1 auto-encode -i "''${FILE}"
  fi
done
      '')
    ];

    services.flatpak.enable = true;

    fonts = {
      fontDir.enable = true;
      enableGhostscriptFonts = true;
      fonts = with pkgs; [
        ubuntu_font_family
        dejavu_fonts
        symbola
      ];
    };

    user.extraGroups = [ "audio" "video" "docker" ];

    # Resolve .local domains
    services.avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };

    xdg.mime = {
      enable = true;
    };
  };
}
