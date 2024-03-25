{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.feature.podman;
  update-containers = pkgs.writeShellScriptBin "update-containers" ''
    	SUDO=""
    	if [[ $(id -u) -ne 0 ]]; then
    		SUDO="doas"
    	fi

      images=$($SUDO ${pkgs.podman}/bin/podman ps -a --format="{{.Image}}" | sort -u)

      for image in $images
      do
        $SUDO ${pkgs.podman}/bin/podman pull $image
      done
  '';
in
{
  options.plusultra.feature.podman = with types; {
    enable = mkBoolOpt false "Whether or not to enable podman.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.lazydocker
      update-containers
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

    systemd.timers.updatecontainers = {
      timerConfig = {
        Unit = "updatecontainers.service";
        OnCalendar = "Mon 02:00";
      };
      wantedBy = [ "timers.target" ];
    };

    systemd.services.updatecontainers = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "update-containers";
      };
    };
  };
}
