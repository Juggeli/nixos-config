{
  flake.homeModules.obsidian = {
    environment.persistence."/persist-home" = {
      users.juggeli.directories = [
        ".config/obsidian"
        "obsidian"
        ".var/app/md.obsidian.Obsidian"
      ];
    };
  };
}
