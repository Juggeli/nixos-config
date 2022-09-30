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
      emacs.enable = true;
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

  systemd.mounts = [{
    what = "//10.11.11.55/pool";
    where = "/mnt/shares";
    type = "samba";
    wantedBy = ["multi-user.target"];
    enable = true;
  }];

  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = false;
}
