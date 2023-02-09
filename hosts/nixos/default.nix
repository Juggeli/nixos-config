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
      gnome.enable = false;
      kde.enable = false;
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
      fish.enable = true;
      util.enable = true;
      rust.enable = true;
    };
    services = {
      ssh.enable = true;
      tailscale.enable = false;
    };
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_1;

  virtualisation.docker.enable = true;

  boot.loader.systemd-boot.memtest86.enable = true;

  environment.systemPackages = [ 
    pkgs.cifs-utils 
    (pkgs.writeShellScriptBin "lock" ''
      if [[ "$1" == this ]]
        then args="-s"
        else args="-san"
      fi
      USER=juggeli ${pkgs.vlock}/bin/vlock "$args"
    '')
  ];
  fileSystems."/mnt/pool" = {
    device = "//10.11.11.2/pool";
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

  services.getty.autologinUser = "juggeli";

  hm.programs.fish.loginShellInit = ''
    if test (tty) = /dev/tty1
      exec sway
    else
      sudo /run/current-system/sw/bin/lock this
    end
  '';

  security.sudo = {
    enable = true;
    extraConfig = ''
      juggeli ALL = (root) NOPASSWD: /run/current-system/sw/bin/lock
      juggeli ALL = (root) NOPASSWD: /run/current-system/sw/bin/lock this
      juggeli ALL = (root) NOPASSWD: /run/current-system/sw/bin/reboot
      juggeli ALL = (root) NOPASSWD: /run/current-system/sw/bin/shutdown
    '';
  };
}
