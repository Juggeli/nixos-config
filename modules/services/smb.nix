{ options, config, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.services.smb;
in {
  options.modules.services.smb = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;

      # note: you will need to run `sudo smbpasswd -a <user>` to enable a user
      securityType = "user";

      extraConfig = ''
        load printers = no
        printcap name = /dev/null
        '';

      # shares should be specified per-host
    };

    networking.firewall = {
      allowedTCPPorts = [ 445 139 ];
      allowedUDPPorts = [ 137 138 ];
    };
  };
}
