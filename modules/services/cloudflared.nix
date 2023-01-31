{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.cloudflared;
in
{
  options.modules.services.cloudflared = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    users.users.cloudflared = {
      group = "cloudflared";
      isSystemUser = true;
    };
    users.groups.cloudflared = { };

    systemd.services.cloudflare-tunnel = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "systemd-resolved.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token=eyJhIjoiMTMyMjkxYzEyNmQ1MTBjZDg1N2VkZGMzNjdhMmM3N2EiLCJ0IjoiMmM0NDc1ZTEtNzdlNC00NmJkLWFhYmUtNDJhMjY1Y2VjNWZkIiwicyI6Ik1ETmpNMkptWmpndE5EQmtZUzAwWXpNMExXRXpaVEF0TURjM01HRTNORFEzTXpSbSJ9";
        Restart = "always";
        User = "cloudflared";
        Group = "cloudflared";
      };
    };
  };
}

