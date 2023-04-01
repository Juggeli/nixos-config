{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.virtualisation.docker;
in
{
  options.plusultra.virtualisation.docker = with types; {
    enable = mkBoolOpt false "Whether or not to enable docker.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";

    plusultra.user.extraGroups = [ "docker" ];

    # Network linker
    system.activationScripts.DockerNetwork =
      let
        backend = config.virtualisation.oci-containers.backend;
        backendBin = "${pkgs.${backend}}/bin/${backend}";
      in
      ''
        ${backendBin} network create docker-net --subnet 172.20.0.0/16 || true
      '';

    virtualisation = {
      docker = {
        enable = cfg.enable;
      };
    };
  };
}
