{
  flake.nixosModules.home-impermanence = {
    environment.persistence."/persist-home".users.juggeli.directories = [
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
    ];
  };
}
