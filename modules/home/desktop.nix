{ self, ... }:
{
  flake.homeModules.desktop.imports = with self.homeModules; [
    base
    kitty
    wezterm
    ghostty
    mpv
    jq
    cw
  ];
}
