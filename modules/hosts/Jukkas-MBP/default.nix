{ self, ... }:
{
  flake.darwinConfigurations."Jukkas-MBP" = self.lib.mkDarwin {
    system = "aarch64-darwin";
    hostName = "Jukkas-MBP";
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
      ])
      ++ [
        {
          system.stateVersion = 4;

          environment.systemPath = [ "/opt/homebrew/bin" ];

          home-manager.users.juggeli = {
            ghostty.fontSize = 16;

            home.sessionVariables = {
              ANDROID_HOME = "$HOME/Library/Android/sdk";
            };

            home.sessionPath = [
              "/opt/homebrew/bin"
              "$HOME/src/flutter/bin"
              "$HOME/.pub-cache/bin"
              "$HOME/.local/bin"
              "$HOME/Library/Android/sdk/platform-tools"
              "$HOME/Library/Android/sdk/emulator"
              "/Applications/microchip/xc8/v2.50/bin"
              "/Applications/microchip/mplabx/6.30/MPLAB X IDE v6.30.app/Contents/Resources/mplab_ide/bin"
            ];
          };
        }
      ];
  };
}
