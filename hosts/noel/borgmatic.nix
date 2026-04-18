{ config, pkgs, ... }:

let
  defaultExcludePatterns = [
    "*/.snapshots/"
    "*/cache/"
    "*/.cache/"
    "*/Cache/"
    "*/Code Cache/"
    "*/heroic/tools/"
    "*/coredump/"
    "*/Steam/"
  ];

  defaultExcludeIfPresent = [ ".nobackup" ];

  defaultRetention = {
    keep_daily = 7;
    keep_weekly = 4;
    keep_monthly = 12;
    keep_yearly = 4;
  };

  defaultChecks = [
    { name = "repository"; }
    {
      name = "archives";
      frequency = "2 weeks";
    }
  ];

  encryptionPasscommand = "${pkgs.coreutils}/bin/cat ${config.age.secrets.borg-passkey.path}";
  sshCommand = "ssh -i /home/juggeli/.ssh/id_ed25519";

  mkBackup =
    {
      directories,
      repositoryUrl ? null,
      repositoryLabel,
      excludePatterns ? defaultExcludePatterns,
    }:
    {
      source_directories = directories;
      repositories = [
        {
          path = if repositoryUrl != null then repositoryUrl else "@${repositoryLabel}-repository-url@";
          label = repositoryLabel;
        }
      ];
      encryption_passcommand = encryptionPasscommand;
      healthchecks.ping_url = "@${repositoryLabel}-healthcheck-url@";
      ssh_command = sshCommand;
      inherit (defaultRetention)
        keep_daily
        keep_weekly
        keep_monthly
        keep_yearly
        ;
      checks = defaultChecks;
      exclude_patterns = excludePatterns;
      exclude_if_present = defaultExcludeIfPresent;
    };

  backups = {
    storagebox = {
      directories = [
        "/persist/"
        "/persist-home/"
      ];
      repositoryLabel = "storagebox";
      repositoryUrlPath = config.age.secrets.storagebox-url.path;
      healthcheckUrlPath = config.age.secrets.borg-healthcheck.path;
    };
    hydrus = {
      directories = [ "/hydrus" ];
      repositoryLabel = "haruka-hydrus";
      repositoryUrl = "ssh://juggeli@haruka/tank/backup/hydrus";
      healthcheckUrlPath = config.age.secrets.borg-hydrus-healthcheck.path;
    };
    hydrus-offsite = {
      directories = [ "/hydrus" ];
      repositoryLabel = "storagebox-hydrus";
      repositoryUrlPath = config.age.secrets.storagebox-hydrus-url.path;
      healthcheckUrlPath = config.age.secrets.borg-hydrus-offsite-healthcheck.path;
      excludePatterns = defaultExcludePatterns ++ [
        "*/client.caches.db*"
        "*/client.mappings.db*"
        "*/.Trash-1000/*"
      ];
    };
  };
in
{
  services.borgmatic = {
    enable = true;
    configurations = builtins.mapAttrs (
      _: backup:
      mkBackup {
        inherit (backup) directories repositoryLabel;
        repositoryUrl = backup.repositoryUrl or null;
        excludePatterns = backup.excludePatterns or defaultExcludePatterns;
      }
    ) backups;
  };

  environment.persistence."/persist".files = [
    "/root/.ssh/known_hosts"
  ];

  system.activationScripts.borgmatic-secrets = {
    text = builtins.concatStringsSep "\n" (
      builtins.attrValues (
        builtins.mapAttrs (
          name: backup:
          let
            configFile = "/etc/borgmatic.d/${name}.yaml";
            label = backup.repositoryLabel;
            repoReplacement =
              if backup ? repositoryUrlPath then
                ''
                  if [ -f "${configFile}" ] && grep -q "@${label}-repository-url@" "${configFile}"; then
                    secret=$(cat "${backup.repositoryUrlPath}")
                    ${pkgs.gnused}/bin/sed -i "s#@${label}-repository-url@#$secret#g" "${configFile}"
                  fi
                ''
              else
                "";
            healthcheckReplacement = ''
              if [ -f "${configFile}" ] && grep -q "@${label}-healthcheck-url@" "${configFile}"; then
                secret=$(cat "${backup.healthcheckUrlPath}")
                ${pkgs.gnused}/bin/sed -i "s#@${label}-healthcheck-url@#$secret#g" "${configFile}"
              fi
            '';
          in
          repoReplacement + healthcheckReplacement
        ) backups
      )
    );
    deps = [
      "agenix"
      "etc"
    ];
  };
}
