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
}