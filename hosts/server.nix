# hosts/server.nix
#
# Only to be used for headless servers, at home or abroad, with more
# security/automation-minded configuration.

{ config, lib, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_1;

  environment.systemPackages = with pkgs; [
    btop
    hddtemp
    screen
    powertop
    smartmontools
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  programs.dconf.enable = true;

  security.acme.defaults.email = "juggeli@gmail.com";

  systemd = {
    services.clear-log = {
      description = "Clear >1 month-old logs every week";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=30d";
      };
    };
    timers.clear-log = {
      wantedBy = [ "timers.target" ];
      partOf = [ "clear-log.service" ];
      timerConfig.OnCalendar = "weekly UTC";
    };
  };
}
