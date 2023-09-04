{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.virtualisation.podman;
in
{
  options.plusultra.virtualisation.podman = with types; {
    enable = mkBoolOpt false "Whether or not to enable podman.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.backend = "podman";

    plusultra.user.extraGroups = [ "podman" ];
    networking.firewall.trustedInterfaces = [ "podman0" ];

    virtualisation = {
      podman = {
        enable = cfg.enable;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
