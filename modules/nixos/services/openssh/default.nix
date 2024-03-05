{ config, lib, format ? "", ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.openssh;
  defaultKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWARTI4cg5EtRCbzZHwsBscipQGful/DkpJDQ8CASRQ"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmwbagg+KRPDgV3YbwFMX8N5QjmqEeDF+gy+jYl3CZc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChg5AbSHcMqXbMCeAAx323By5pL0hHPoBSMgMaktxo7"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbJeg8M8Pmbab+/X5on+hFEJlLW0/f4vX8nNtDNAcox"
  ];
in
{
  options.plusultra.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys =
      mkOpt (listOf str) defaultKeys "The public keys to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;

      settings = {
        PermitRootLogin =
          if format == "install-iso"
          then "yes"
          else "no";
        PasswordAuthentication = false;
      };

      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      ports = [
        22
        cfg.port
      ];
    };

    programs.ssh.startAgent = true;

    plusultra.user.extraOptions.openssh.authorizedKeys.keys =
      cfg.authorizedKeys;

    plusultra.filesystem.impermanence.directories = [
      "/etc/ssh"
    ];
  };
}
