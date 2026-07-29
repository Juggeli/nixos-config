{
  flake.nixosModules.haruka-zfs-tank =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      boot.zfs.extraPools = [ "tank" ];

      systemd.services.zfs-load-key = {
        description = "Load ZFS encryption key for tank pool";
        after = [ "zfs-import.target" ];
        wants = [ "zfs-import.target" ];
        wantedBy = [ "zfs-mount.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.zfs}/bin/zfs load-key -L file://${config.age.secrets.zfs.path} tank";
        };
      };

      boot.initrd = {
        luks.forceLuksSupportInInitrd = true;
        network.enable = true;
        network.ssh = {
          enable = true;
          port = 22;
          authorizedKeys = config.users.users.juggeli.openssh.authorizedKeys.keys;
          hostKeys = [ /etc/ssh/ssh_host_ed25519_key ];
        };
        secrets = {
          "/etc/ssh/ssh_host_ed25519_key" = /etc/ssh/ssh_host_ed25519_key;
        };
        # Prompt for LUKS passphrases immediately on SSH login.
        systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
      };
    };
}
