{
  modulesPath,
  lib,
  config,
  pkgs,
  ...
}:

with lib;
with lib.plusultra;
let
  startpool = pkgs.writeShellScriptBin "startpool" ''
    doas cryptsetup open /dev/vdb1 pool
    doas mount -o noatime,nodatacow /dev/mapper/pool /mnt
    doas systemctl restart podman-qbittorrent.service
  '';
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  environment.systemPackages = [
    startpool
  ];

  plusultra = {
    suites = {
      common-slim = enabled;
    };

    containers = {
      qbittorrent = enabled;
    };

    services = {
      tailscale.port = 50288;
    };

    feature = {
      podman = enabled;
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
