{
  flake.nixosModules.home-impermanence = {
    environment.persistence."/persist-home".users.juggeli = {
      directories = [
        ".ssh"
        ".local/share/direnv"
        ".local/state/wireplumber"
        ".config/1Password"
        ".config/SuperSlicer"
        ".npm"
        ".var/app"
        "src"
        "downloads"
        "documents"
        "games"
        "My Games"

        ".cache/bat"
        ".local/share/fish"
        ".local/share/zoxide"
        ".cache/fish"
        ".local/share/uv"
        ".cache/uv"
        ".codex"
        ".gemini"
        ".claude"
        ".config/claude"
        ".local/state/nvim"
        ".local/share/nvim"
        ".cache/nvim"
        ".config/github-copilot"
        ".cache/opencode"
        ".config/opencode"
        ".local/share/opencode"
        ".local/state/opencode"
        ".pi"
      ];
      files = [
        ".claude.json"
        ".config/lazygit/state.yml"
      ];
    };
  };
}
