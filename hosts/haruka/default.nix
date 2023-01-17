{ pkgs, config, lib, ... }:
{
  imports = [
    ../home.nix
    ../server.nix
    ./hardware-configuration.nix
    # ./pool.nix
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
      grafana.enable = false;
      prometheus.enable = false;
      plex.enable = false;
      qbittorrent.enable = false;
      jackett.enable = false;
      sonarr.enable = false;
      homeassistant.enable = false;
      tailscale.enable = false;
    };
  };

  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  networking.interfaces.enp3s0.ipv4.addresses = [{
    address = "10.11.11.3";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.11.11.1";
  networking.nameservers = [ "1.1.1.1" ];

  boot.kernelParams = [ "ip=10.11.11.3::10.11.11.1:255.255.255.0:haruka:enp3s0:off" ];

  boot.loader.supportsInitrdSecrets = true;
  boot.initrd = {
    luks.forceLuksSupportInInitrd = true;
    network.enable = true;
    preLVMCommands = lib.mkOrder 400 "sleep 1";
    network.ssh = {
      enable = true;
      port = 22;
      authorizedKeys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWARTI4cg5EtRCbzZHwsBscipQGful/DkpJDQ8CASRQ juggeli@gmail.com"
      ];
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

