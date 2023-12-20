{ lib }:

{
  mkBorgBackup = { config, paths, exclude ? [ ] }: {
    inherit paths;
    inherit exclude;
    repo = "ssh://u342924@u342924.your-storagebox.de:23/./backups/${config.networking.hostName}";
    compression = "auto,zstd";
    environment.BORG_RSH = "ssh -i /home/juggeli/.ssh/id_ed25519";
    encryption.mode = "repokey";
    encryption.passCommand = "cat ${config.age.secrets.borg-passkey.path}";
    startAt = "daily";
    prune.keep = {
      within = "1d"; # Keep all archives from the last day
      daily = 7;
      weekly = 4;
      monthly = -1; # Keep at least one archive for each month
    };
  };
}
