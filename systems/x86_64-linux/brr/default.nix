{ modulesPath, lib, config, ... }:

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
      authorizedKeys = config.plusultra.services.openssh.authorizedKeys;
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
