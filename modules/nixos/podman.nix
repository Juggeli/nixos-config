{
  flake.nixosModules.podman =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lazydocker
        pkgs.podman-compose
      ];

      virtualisation.oci-containers.backend = "podman";

      # Podman keeps auto-detecting an existing BoltDB state forever, even though
      # new installs default to SQLite. Pinning the backend makes podman refuse to
      # start against a stray bolt_state.db instead of silently reviving the
      # deprecated driver, which Podman 6.0 removes.
      virtualisation.containers.containersConf.settings.engine.db_backend = "sqlite";

      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
        autoPrune.enable = true;
      };

      users.users.juggeli.extraGroups = [ "podman" ];

      # Containers only need the host for aardvark-dns on 10.88.0.1:53; they reach
      # each other over the bridge and the outside world via masquerade, neither of
      # which passes through INPUT. Trusting podman0 wholesale would instead expose
      # every host service bound to 0.0.0.0 — sshd, Samba, Syncthing — to any
      # container, which matters because container images update unattended.
      networking.firewall.interfaces.podman0 = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
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
