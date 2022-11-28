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
      webcord-overlay.packages.${pkgs.system}.default
      btop
      powertop
      via
      (writeShellScriptBin "enc-all" ''    
shopt -s nullglob
shopt -s globstar
for FILE in ''$1/**/*.mkv
do
  CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "''${FILE}");
  if [[ $CODEC != "av1" ]]; then
    echo "File ''${FILE} is not av1";
    enc-auto "''${FILE}"
  fi
done
      '')
      (writeShellScriptBin "enc-crf" ''
        ab-av1 encode -e libsvtav1 --preset 10 \
        --acodec libopus --enc b:a=48k --enc vbr=on \
        --enc compression_level=10 --enc frame_duration=60 \
        --enc application=audio --crf 30 \
        --pix-format yuv420p10le -i "''$1"
      '')
      (writeShellScriptBin "enc-auto" ''
        ab-av1 auto-encode -e libsvtav1 --preset 10 \
        --vmaf model=path=/usr/share/model/vmaf_v0.6.1.json \
        --acodec libopus --enc b:a=48k --enc vbr=on \
        --enc compression_level=10 --enc frame_duration=60 \
        --enc application=audio \
        --pix-format yuv420p10le -i "''$1"
      '')
      (writeShellScriptBin "enc-anime" ''
        ab-av1 encode --crf 23 -e libx265 --acodec libopus \
          --enc b:a=128k --enc vbr=on \
          --enc x265-params=bframes=8:psy-rd=1:aq-mode=3:preset=slow \
          -i "''$1"
      '')
    ];

    services.flatpak.enable = true;
    services.fwupd.enable = true;

    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';

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
