{ config, lib, ... }:

with lib;
{
  networking.hosts =
    let hostConfig = {
          "10.11.11.5"  = [ "asuka" ];
          "10.11.11.2"  = [ "haruka" ];
        };
        hosts = flatten (attrValues hostConfig);
        hostName = config.networking.hostName;
    in mkIf (builtins.elem hostName hosts) hostConfig;

  time.timeZone = mkDefault "Europe/Helsinki";
  i18n.defaultLocale = mkDefault "en_US.UTF-8";

  services.openssh.knownHosts = {
    asuka = {
      extraHostNames = [ "10.11.11.5" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOKNNi9y7KLAOJIJdUNAQaiEvzZWevYhxMo5RplDCnQ";
    };
    # nixos = {
    #   extraHostNames = [ "10.11.11.3"];
    #   publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com";
    # };
  };

  programs.dconf.enable = true;

  users.users.juggeli.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com"
  ];
}
