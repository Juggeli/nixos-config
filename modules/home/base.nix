{ self, ... }:
{
  flake.homeModules.base.imports = with self.homeModules; [
    fish
    nh
    neovim
    btop
    lazygit
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
  ];
}
