{ pkgs, config, lib, ... }:
{
  imports = [
    ../home.nix
    ../server.nix
    ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
    editors = {
      default = "nvim";
      vim.enable = true;
    };
    shell = {
      git.enable    = true;
      zsh.enable    = true;
    };
    services = {
      ssh.enable = true;
    };
    theme.enable = true;
  };

  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = false;

  virtualisation.docker.enable = true;

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
    # network.postCommands = let
    #   disk = "/dev/disk/by-label/crypt";
    # in ''
    #   echo 'cryptsetup open ${disk} root --type luks && echo > /tmp/continue' >> /root/.profile
    #   echo 'starting sshd...'
    #   '';
    # postDeviceCommands = ''
    #   echo 'waiting for root device to be opened...'
    #   mkfifo /tmp/continue
    #   cat /tmp/continue
    #   '';
  };
}
