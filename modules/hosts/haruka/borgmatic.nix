{
  flake.nixosModules.haruka-borgmatic =
    { config, pkgs, ... }:
    {
      services.borgmatic = {
        enable = true;
        configurations.storagebox = {
          source_directories = [ "/mnt/appdata" ];
          repositories = [
            {
              path = "@storagebox-repository-url@";
              label = "storagebox";
            }
          ];
          encryption_passcommand = "${pkgs.coreutils}/bin/cat ${config.age.secrets.borg-passkey.path}";
          healthchecks.ping_url = "@storagebox-healthcheck-url@";
          ssh_command = "ssh -i /home/juggeli/.ssh/id_ed25519";
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
          exclude_if_present = [ ".nobackup" ];
        };
      };

      system.activationScripts.borgmatic-secrets = {
        text = ''
          configFile=/etc/borgmatic.d/storagebox.yaml
          if [ -f "$configFile" ] && grep -q "@storagebox-repository-url@" "$configFile"; then
            secret=$(cat "${config.age.secrets.storagebox-url.path}")
            ${pkgs.gnused}/bin/sed -i "s#@storagebox-repository-url@#$secret#g" "$configFile"
          fi
          if [ -f "$configFile" ] && grep -q "@storagebox-healthcheck-url@" "$configFile"; then
            secret=$(cat "${config.age.secrets.borg-healthcheck.path}")
            ${pkgs.gnused}/bin/sed -i "s#@storagebox-healthcheck-url@#$secret#g" "$configFile"
          fi
        '';
        deps = [
          "agenix"
          "etc"
        ];
      };
    };
}
