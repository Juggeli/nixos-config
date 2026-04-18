{
  flake.nixosModules.networking = {
    networking.networkmanager = {
      enable = true;
      dhcp = "internal";
    };

    networking.hosts."127.0.0.1" = [ "local.test" ];

    users.users.juggeli.extraGroups = [ "networkmanager" ];

    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
