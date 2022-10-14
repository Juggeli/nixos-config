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
      apps = {
        rofi.enable = true;
      };
      browsers = {
        default = "google-chrome-stable";
        chrome.enable = true;
      };
      media = {
        mpv.enable = true;
      };
      term = {
        default = "alacritty";
        alacritty.enable = true;
      };
      sway = {
        enable = true;
        # wallpaper = ./config/bg1.jpg; 
      };
      hyprland.enable = false;
    };
    editors = {
      default = "nvim";
      emacs = {
        enable = true;
        doom.enable = true;
      };
      vim.enable = true;
    };
    shell = {
      git.enable = true;
      zsh.enable = true;
    };
    services = {
      ssh.enable = true;
    };
    theme.enable = true;
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;

  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/shares" = {
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
