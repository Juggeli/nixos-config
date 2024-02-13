{ modulesPath, lib, ... }:

with lib;
with lib.plusultra; {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  plusultra = {
    suites = {
      common-slim = enabled;
    };

    services = {
      openssh = {
        enable = true;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMRlC0Hzv2D+8e0m1/XT27b7RaMLm9wX16bz6TJPKdt jukka"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbJeg8M8Pmbab+/X5on+hFEJlLW0/f4vX8nNtDNAcox jukka"
        ];
      };
    };
  };

  boot.loader.supportsInitrdSecrets = true;
  boot.initrd = {
    luks.forceLuksSupportInInitrd = true;
    network.enable = true;
    preLVMCommands = lib.mkOrder 400 "sleep 1";
    network.ssh = {
      enable = true;
      port = 22;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMRlC0Hzv2D+8e0m1/XT27b7RaMLm9wX16bz6TJPKdt jukka"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbJeg8M8Pmbab+/X5on+hFEJlLW0/f4vX8nNtDNAcox jukka"
      ];
      hostKeys = [ /etc/ssh/ssh_host_ed25519_key ];
    };
    secrets = {
      "/etc/ssh/ssh_host_ed25519_key" = /etc/ssh/ssh_host_ed25519_key;
    };
    network.postCommands = ''
      echo 'cryptsetup-askpass' >> /root/.profile
    '';
  };

  system.stateVersion = "23.11";
}
