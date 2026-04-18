{
  flake.nixosModules.openssh = {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
      extraConfig = ''
        StreamLocalBindUnlink yes
      '';
      ports = [
        22
        2222
      ];
    };

    programs.ssh.startAgent = true;

    users.users.juggeli.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWARTI4cg5EtRCbzZHwsBscipQGful/DkpJDQ8CASRQ"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmwbagg+KRPDgV3YbwFMX8N5QjmqEeDF+gy+jYl3CZc"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChg5AbSHcMqXbMCeAAx323By5pL0hHPoBSMgMaktxo7"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbJeg8M8Pmbab+/X5on+hFEJlLW0/f4vX8nNtDNAcox"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICIOMommfZHNSlOeE2lbfHhQ8S3+H4iSi7BOYItZqhOQ phone"
    ];

    environment.persistence."/persist".directories = [ "/etc/ssh" ];
  };
}
