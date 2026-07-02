{ self, ... }:
{
  flake.darwinConfigurations.kuro = self.lib.mkDarwin {
    system = "aarch64-darwin";
    hostName = "kuro";
    modules =
      (with self.darwinModules; [
        base
        home-manager
        nix-settings
        fonts
        input
        interface
        user
        homebrew
        aerospace
        raycast
        agenix
        agenix-shared
        tailscale
      ])
      ++ (with self.homeModules; [
        kitty
        wezterm
        ghostty
        mpv
        fish
        gh
        nh
        neovim
        btop
        lazygit
        jq
        yazi
        bat
        ai-agents
        pi
        opencode
        claude-code
        tmux
        cw
        git
        direnv
        devtools
        hdd-scraper
        syncthing
      ])
      ++ [
        { system.stateVersion = 6; }
      ];
  };
}
