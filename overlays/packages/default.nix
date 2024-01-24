{ channels, ... }:

final: prev:

{
  inherit (channels.unstable) discord;
  inherit (channels.unstable) hyprland;
  inherit (channels.unstable) catppuccin-gtk;
  inherit (channels.unstable) cloudflared;
  inherit (channels.unstable) plex;
  inherit (channels.unstable) vscode-fhs;
  inherit (channels.unstable) wezterm;
  inherit (channels.unstable) obsidian;
  inherit (channels.unstable) nix-direnv;
  inherit (channels.unstable) neovim;
  inherit (channels.unstable) monero-gui;
  inherit (channels.unstable) lua-language-server;
  inherit (channels.unstable) ledger-live-desktop;
}
