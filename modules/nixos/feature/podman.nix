{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.feature.podman;
in
{
  options.plusultra.feature.podman = with types; {
    enable = mkBoolOpt false "Whether or not to enable podman.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.lazydocker
    ];
    virtualisation.oci-containers.backend = "podman";

    plusultra.user.extraGroups = [ "podman" ];
    networking.firewall.trustedInterfaces = [ "podman0" ];

    virtualisation = {
      podman = {
        enable = cfg.enable;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
        autoPrune.enable = true;
      };
    };

    systemd.timers.podman-auto-update = {
      timerConfig = {
        OnCalendar = "06:00";
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };

    systemd.services.podman-auto-update = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.podman}/bin/podman auto-update";
        ExecStartPost = "${pkgs.systemd}/bin/systemctl restart podman-auto-update-dependent.target";
      };
    };

    systemd.targets.podman-auto-update-dependent = {
      description = "Target for services that depend on podman auto-update";
    };
  };
}
