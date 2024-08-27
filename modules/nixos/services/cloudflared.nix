{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.cloudflared;
in
{
  options.plusultra.services.cloudflared = with types; {
    enable = mkBoolOpt false "Whether or not to enable cloudflared tunnel.";
  };

  config = mkIf cfg.enable {
    users.users.cloudflared = {
      group = "cloudflared";
      isSystemUser = true;
    };
    users.groups.cloudflared = { };

    age.secrets.cloudflared = {
      owner = "cloudflared";
      group = "cloudflared";
      mode = "770";
    };

    systemd.services.cloudflare-tunnel = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "systemd-resolved.service"
      ];
      serviceConfig = {
        Restart = "always";
        User = "cloudflared";
        Group = "cloudflared";
      };
      script = ''
        TOKEN=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.cloudflared.path})
        ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token=$TOKEN
      '';
    };
  };
}
