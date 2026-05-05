{
  flake.nixosModules.haruka-samba = {
    networking.firewall = {
      allowedTCPPorts = [ 5357 ];
      allowedUDPPorts = [ 3702 ];
    };

    services.samba-wsdd = {
      enable = true;
      discovery = true;
      workgroup = "WORKGROUP";
    };

    services.samba = {
      enable = true;
      openFirewall = true;
      settings.tank = {
        path = "/tank";
        comment = "tank";
        public = "no";
        browseable = "yes";
        "read only" = "no";
      };
    };
  };
}
