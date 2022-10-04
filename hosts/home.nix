{ config, lib, ... }:

with lib;
{
  networking.hosts =
    let hostConfig = {
          "10.11.11.3"  = [ "rei" ];
        };
        hosts = flatten (attrValues hostConfig);
        hostName = config.networking.hostName;
    in mkIf (builtins.elem hostName hosts) hostConfig;

  time.timeZone = mkDefault "Europe/Helsinki";
  i18n.defaultLocale = mkDefault "en_US.UTF-8";

  services.openssh.knownHosts = {
    asuka = {
      extraHostNames = [ "10.11.11.2" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEFJt9V3nuMuU0BrWrDZT85SeTXQw9v4KWz664FCD7K juggeli@gmail.com";
    };
    nixos = {
      extraHostNames = [ "10.11.11.3"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com";
    };
  };

  users.users.juggeli.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com"
  ];
}
