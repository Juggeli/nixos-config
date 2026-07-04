{ self, ... }:
{
  flake.nixosConfigurations.haruka = self.lib.mkNixos {
    system = "x86_64-linux";
    hostName = "haruka";
    modules =
      (with self.nixosModules; [
        nix-settings
        users-juggeli
        home-manager
        boot
        zfs
        openssh
        tailscale
        agenix
        agenix-shared
        doas
        podman
        tools-misc
        hardware-storage
        system-fonts
        system-locale
        system-time

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
        fish
        nh
        neovim
        btop
        rclone
        lazygit
        ffmpeg
        ab-av1
        yazi
        ai-agents
        pi
        opencode
        claude-code
        bat
        tmux
        gh
        git
        direnv
        devtools
        hdd-scraper
      ]);
  };
}
