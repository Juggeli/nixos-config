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
        haruka-samba
        haruka-acme
        haruka-cleanup
        haruka-qbittorrent-manager
        haruka-markdown-viewer
        haruka-log-analyzer
        haruka-containers
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
