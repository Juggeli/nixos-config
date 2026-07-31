{ self, ... }:
{
  flake.nixosConfigurations.haruka = self.lib.mkNixos {
    hostName = "haruka";
    modules =
      (with self.nixosModules; [
        base

        haruka-no-impermanence
        haruka-system
        haruka-hardware
        haruka-zfs-tank
        haruka-storage
        haruka-syncthing
        haruka-borgmatic
        haruka-cloudflared
        haruka-tailscale-serve
        haruka-samba
        haruka-acme
        haruka-cleanup
        haruka-qbittorrent-manager
        haruka-log-analyzer
        haruka-portion-calculator
        haruka-containers
        haruka-arr-api-keys
        haruka-homepage
        haruka-media-stack
      ])
      ++ (with self.homeModules; [
        base
        rclone
        ffmpeg
        ab-av1
      ]);
  };
}
