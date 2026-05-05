{ self, ... }:
{
  flake.nixosConfigurations.haruka = self.lib.mkNixos {
    system = "x86_64-linux";
    hostName = "haruka";
    modules = with self.nixosModules; [
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

      home-fish
      home-nh
      home-neovim
      home-btop
      home-rclone
      home-lazygit
      home-ffmpeg
      home-ab-av1
      home-yazi
      home-ai-agents
      home-pi
      home-opencode
      home-claude-code
      home-bat
      home-tmux
      home-gh
      home-git
      home-direnv
      home-devtools
      home-hdd-scraper

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
    ];
  };
}
