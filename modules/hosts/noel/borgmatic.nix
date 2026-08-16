{
  flake.nixosModules.noel-borgmatic =
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

      # Run while the machine is normally in use instead of upstream's
      # midnight default; the empty entry clears the inherited OnCalendar.
      systemd.timers.borgmatic.timerConfig.OnCalendar = [
        ""
        "18:00"
      ];

      # Forcing the machine to sleep bypasses borgmatic's sleep inhibitor
      # and severs the ssh connection mid-backup, so the run errors out on
      # wake. Stop the service cleanly before sleeping and start it again
      # after resume; borg reuses the already-transferred chunks.
      systemd.services.borgmatic-sleep-stop = {
        description = "stop borgmatic before sleep";
        before = [ "sleep.target" ];
        wantedBy = [ "sleep.target" ];
        path = [ pkgs.systemd ];
        serviceConfig.Type = "oneshot";
        script = ''
          if systemctl is-active --quiet borgmatic.service; then
            touch /run/borgmatic-interrupted-by-sleep
            systemctl stop borgmatic.service
          fi
        '';
      };

      systemd.services.borgmatic-resume = {
        description = "restart borgmatic interrupted by sleep";
        after = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
          "suspend-then-hibernate.target"
        ];
        wantedBy = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
          "suspend-then-hibernate.target"
        ];
        path = [ pkgs.systemd ];
        serviceConfig.Type = "oneshot";
        script = ''
          if [ -e /run/borgmatic-interrupted-by-sleep ]; then
            rm /run/borgmatic-interrupted-by-sleep
            systemctl start --no-block borgmatic.service
          fi
        '';
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
    };
}
