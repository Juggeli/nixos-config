{ pkgs, config, lib, ... }:
{
  imports = [
    ../home.nix
    ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
    desktop = {
      generic.enable = true;
      fonts.enable = true;
      browsers = {
        chrome.enable = true;
      };
      media = {
        mpv.enable = true;
        ffmpeg.enable = true;
      };
      term = {
        alacritty.enable = true;
        kitty.enable = true;
      };
      sway.enable = true;
      gnome.enable = true;
    };
    editors = {
      emacs = {
        enable = true;
        doom.enable = true;
      };
      vim.enable = true;
      vifm.enable = true;
    };
    shell = {
      git.enable = true;
      zsh.enable = true;
      rust.enable = true;
    };
    services = {
      ssh.enable = true;
    };
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_testing;

  virtualisation.docker.enable = true;

  boot.loader.systemd-boot.memtest86.enable = true;

  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/pool" = {
    device = "//asuka/pool";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

      in
      [ "${automount_opts},credentials=/etc/nixos/smb-secrets,uid=1001,gid=100" ];
  };

  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = false;
}
