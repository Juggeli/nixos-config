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
in
{
  options.plusultra.feature.borgmatic = with types; {
    enable = mkBoolOpt false "Whether or not to enable borgmatic.";
    directories = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Directories that should be backed up with borgmatic";
    };
  };

  config = mkIf cfg.enable {
    services.borgmatic = {
      enable = true;
      settings = {
        source_directories = cfg.directories;
        repositories = [
          {
            path = "ssh://@storagebox-url@/./backups/${config.networking.hostName}";
            label = "storagebox";
          }
        ];
        encryption_passcommand = "${pkgs.coreutils}/bin/cat ${config.age.secrets.borg-passkey.path}";
        healthchecks = {
          ping_url = "@healthcheck-url@";
        };
        ssh_command = "ssh -i /home/${config.plusultra.user.name}/.ssh/id_ed25519";
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 12;
        keep_yearly = 4;
        checks = [
          { name = "repository"; }
          {
            name = "archives";
            frequency = "2 weeks";
          }
        ];
        exclude_patterns = [
          "*/.snapshots/"
          "*/cache/"
          "*/.cache/"
          "*/Cache/"
          "*/Code Cache/"
          "*/heroic/tools/"
          "*/coredump/"
          "*/Steam/"
        ];
        exclude_if_present = [
          ".nobackup"
        ];
      };
    };

    plusultra.filesystem.impermanence = {
      files = [
        "/root/.ssh/known_hosts"
      ];
    };

    system.activationScripts."healthcheck-secret" = ''
      configFile=/etc/borgmatic/config.yaml
      secret=$(cat "${config.age.secrets.borg-healthcheck.path}")
      ${pkgs.gnused}/bin/sed -i "s#@healthcheck-url@#$secret#" "$configFile"
      secret=$(cat "${config.age.secrets.storagebox-url.path}")
      ${pkgs.gnused}/bin/sed -i "s#@storagebox-url@#$secret#" "$configFile"
    '';
  };
}
