{ pkgs, config, lib, ... }:
{
  imports = [
    ../home.nix
    ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
    desktop = {
      apps = {
        rofi.enable = true;
        # godot.enable = true;
      };
      browsers = {
        default = "firefox";
        firefox.enable = true;
      };
      media = {
        mpv.enable = true;
      };
      term = {
        default = "alacritty";
        alacritty.enable = true;
      };
      sway.enable = true;
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
    theme.active = "alucard";
  };

  systemd.mounts = [{
    what = "Shares";
    where = "/mnt/shares";
    type = "virtiofs";
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