{ pkgs, config, lib, ... }:
{
  imports = [
    ../home.nix
    ../server.nix
    ./hardware-configuration.nix
    ./pool.nix
  ];

  ## Modules
  modules = {
    desktop = {
      term.kitty.enable = true;
      media.ffmpeg.enable = true;
    };
    editors = {
      vim.enable = true;
      vifm.enable = true;
    };
    shell = {
      git.enable = true;
      fish.enable = true;
      util.enable = true;
    };
    services = {
      ssh.enable = true;
      smb.enable = true;
      grafana.enable = true;
      prometheus.enable = true;
      plex.enable = true;
      qbittorrent.enable = true;
      jackett.enable = true;
      sonarr.enable = true;
      homeassistant.enable = true;
      tailscale.enable = true;
    };
  };

  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  networking.interfaces.enp3s0.ipv4.addresses = [{
    address = "10.11.11.2";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.11.11.1";
  networking.nameservers = [ "1.1.1.1" ];

  virtualisation.docker.enable = true;

  swapDevices = [{ device = "/swapfile"; size = 10000; }];

  boot.kernelParams = [ "ip=10.11.11.2::10.11.11.1:255.255.255.0:asuka:enp3s0:off" ];

  boot.loader.supportsInitrdSecrets = true;
  boot.initrd = {
    luks.forceLuksSupportInInitrd = true;
    network.enable = true;
    preLVMCommands = lib.mkOrder 400 "sleep 1";
    network.ssh = {
      enable = true;
      port = 22;
      authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com" ];
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    };
    secrets = {
      "/etc/secrets/initrd/ssh_host_ed25519_key" = "/etc/secrets/initrd/ssh_host_ed25519_key";
    };
    network.postCommands = ''
      echo 'cryptsetup-askpass' >> /root/.profile
    '';
  };

  services.samba = {
    shares = {
      pool = {
        path = "/mnt/pool";
        browseable = "yes";
        writeable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "force user" = "juggeli";
      };
    };
  };
}
