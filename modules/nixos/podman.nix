{
  flake.nixosModules.podman =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lazydocker
        pkgs.podman-compose
      ];

      virtualisation.oci-containers.backend = "podman";
      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
        autoPrune.enable = true;
      };

      users.users.juggeli.extraGroups = [ "podman" ];
      networking.firewall.trustedInterfaces = [ "podman0" ];

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
