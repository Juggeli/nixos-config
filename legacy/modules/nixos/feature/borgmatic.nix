{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.feature.borgmatic;

  backupType = types.submodule {
    options = {
      directories = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Directories to backup in this configuration";
      };

      repository = mkOption {
        type = types.submodule {
          options = {
            url = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Repository URL (use this OR url_path)";
            };
            label = mkOption {
              type = types.str;
              description = "Repository label";
            };
            url_path = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "Path where to read repository url (use this OR url)";
            };
          };
        };
        description = "Repository configuration";
      };

      encryption_passcommand = mkOption {
        type = types.str;
        default = "${pkgs.coreutils}/bin/cat ${config.age.secrets.borg-passkey.path}";
        description = "Command to get encryption passphrase";
      };

      healthcheck_url_path = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path where to read healthcheck ping URL";
      };

      ssh_command = mkOption {
        type = types.str;
        default = "ssh -i /home/${config.plusultra.user.name}/.ssh/id_ed25519";
        description = "SSH command for repository access";
      };

      retention = mkOption {
        type = types.submodule {
          options = {
            keep_daily = mkOption {
              type = types.int;
              default = 7;
              description = "Number of daily backups to keep";
            };
            keep_weekly = mkOption {
              type = types.int;
              default = 4;
              description = "Number of weekly backups to keep";
            };
            keep_monthly = mkOption {
              type = types.int;
              default = 12;
              description = "Number of monthly backups to keep";
            };
            keep_yearly = mkOption {
              type = types.int;
              default = 4;
              description = "Number of yearly backups to keep";
            };
          };
        };
        default = { };
        description = "Backup retention policy";
      };

      exclude_patterns = mkOption {
        type = types.listOf types.str;
        default = [
          "*/.snapshots/"
          "*/cache/"
          "*/.cache/"
          "*/Cache/"
          "*/Code Cache/"
          "*/heroic/tools/"
          "*/coredump/"
          "*/Steam/"
        ];
        description = "Patterns to exclude from backup";
      };

      exclude_if_present = mkOption {
        type = types.listOf types.str;
        default = [ ".nobackup" ];
        description = "Exclude directories containing these files";
      };
    };
  };
in
{
  options.plusultra.feature.borgmatic = with types; {
    enable = mkBoolOpt false "Whether or not to enable borgmatic.";

    backups = mkOption {
      type = types.attrsOf backupType;
      default = { };
      description = "Multiple backup configurations";
      example = {
        storagebox = {
          directories = [
            "/persist"
            "/persist-home"
          ];
          repository = {
            url = "ssh://haruka/tank/backup/example";
            label = "storagebox";
          };
          healthcheck_url_path = config.age.secrets.healthcheck-url.path;
        };
      };
    };
  };

  config = mkIf cfg.enable (
    let
      borgmaticConfigs = mapAttrs (name: backup: {
        source_directories = backup.directories;
        repositories = [
          {
            path = if backup.repository.url != null then backup.repository.url else "@${name}-repository-url@";
            label = backup.repository.label;
          }
        ];
        encryption_passcommand = backup.encryption_passcommand;
        healthchecks = optionalAttrs (backup.healthcheck_url_path != null) {
          ping_url = "@${name}-healthcheck-url@";
        };
        ssh_command = backup.ssh_command;
        keep_daily = backup.retention.keep_daily;
        keep_weekly = backup.retention.keep_weekly;
        keep_monthly = backup.retention.keep_monthly;
        keep_yearly = backup.retention.keep_yearly;
        checks = [
          { name = "repository"; }
          {
            name = "archives";
            frequency = "2 weeks";
          }
        ];
        exclude_patterns = backup.exclude_patterns;
        exclude_if_present = backup.exclude_if_present;
      }) cfg.backups;
    in
    {
      services.borgmatic = {
        enable = true;
        configurations = borgmaticConfigs;
      };

      plusultra.filesystem.impermanence = {
        files = [
          "/root/.ssh/known_hosts"
        ];
      };

      # Replace secrets in borgmatic configurations during system activation
      system.activationScripts.borgmatic-secrets = {
        text = concatStringsSep "\n" (
          mapAttrsToList (
            name: backup:
            let
              configFile = "/etc/borgmatic.d/${name}.yaml";
              repoReplacement = optionalString (backup.repository.url_path != null) ''
                if [ -f "${configFile}" ] && grep -q "@${name}-repository-url@" "${configFile}"; then
                  secret=$(cat "${backup.repository.url_path}")
                  ${pkgs.gnused}/bin/sed -i "s#@${name}-repository-url@#$secret#g" "${configFile}"
                fi
              '';
              healthcheckReplacement = optionalString (backup.healthcheck_url_path != null) ''
                if [ -f "${configFile}" ] && grep -q "@${name}-healthcheck-url@" "${configFile}"; then
                  secret=$(cat "${backup.healthcheck_url_path}")
                  ${pkgs.gnused}/bin/sed -i "s#@${name}-healthcheck-url@#$secret#g" "${configFile}"
                fi
              '';
            in
            repoReplacement + healthcheckReplacement
          ) cfg.backups
        );
        deps = [
          "agenix"
          "etc"
        ];
      };
    }
  );
}
