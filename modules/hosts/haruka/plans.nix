{
  flake.nixosModules.haruka-plans =
    { config, pkgs, ... }:
    let
      dataDir = "/mnt/appdata/plans";
    in
    {
      users.groups.plans = { };
      users.users.plans = {
        isSystemUser = true;
        group = "plans";
      };
      systemd.tmpfiles.rules = [ "d ${dataDir} 0750 plans plans -" ];
      systemd.services.plans = {
        description = "HTML draft publishing";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        unitConfig.RequiresMountsFor = [ dataDir ];
        environment = {
          DATA_DIR = dataDir;
          KEY_FILE = "%d/publish-key";
          PUBLIC_URL = "https://plans.jugi.cc";
          PORT = "8092";
        };
        restartTriggers = [ config.age.secrets.plans-publish-key.file ];
        serviceConfig = {
          LoadCredential = "publish-key:${config.age.secrets.plans-publish-key.path}";
          ExecStart = "${pkgs.python3}/bin/python3 ${../../../packages/plans/server.py}";
          User = "plans";
          Group = "plans";
          Restart = "on-failure";
          UMask = "0077";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          ReadWritePaths = [ dataDir ];
          RestrictAddressFamilies = [ "AF_INET" ];
        };
      };
    };
}
