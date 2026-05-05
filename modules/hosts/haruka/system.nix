{
  flake.nixosModules.haruka-system =
    { config, pkgs, ... }:
    let
      luks-backup = pkgs.luks-backup.override {
        partitionUuids = [
          "585f6048-46df-4d11-a7f8-36a37b932a97"
          "b2fae3e5-97e0-425b-aa55-000eead6465e"
          "7064f0ca-116c-4ef8-af27-53f38552a492"
          "ed5f89cd-cf85-491a-b0f9-915d06d96465"
        ];
      };
    in
    {
      networking.hostId = "37bf5335";

      programs.nix-ld.enable = true;

      services.tailscale.authKeyFile = config.age.secrets.tailscale-auth.path;

      environment.systemPackages = [ luks-backup ];

      users.groups.media.gid = 983;

      boot.kernelParams = [
        "zfs.zfs_arc_shrinker_limit=0"
        "zfs.zfs_arc_max=8589934592"
      ];

      boot.loader.supportsInitrdSecrets = true;

      services.openssh.hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];

      age.identityPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];

      system.stateVersion = "23.05";
    };
}
