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
      settings = {
        # enp1s0 carries both the LAN address and a globally routable IPv6, so
        # the firewall's port rules cannot separate them. Samba does its own
        # source filtering instead.
        global = {
          "hosts allow" = "10.11.11.0/24 100.64.0.0/10 127.0.0.1";
          "hosts deny" = "ALL";
          "server min protocol" = "SMB3";
        };
        tank = {
          path = "/tank";
          comment = "tank";
          public = "no";
          browseable = "yes";
          "read only" = "no";
        };
      };
    };
  };
}
