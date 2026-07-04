{ inputs, ... }:
{
  flake.overlays.default = final: prev: {
    unstable = import inputs.unstable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

    banana-cursor-dreams = prev.callPackage ../packages/banana-cursor-dreams { };
    comic-code = prev.callPackage ../packages/comic-code { };
    hdd-scraper = prev.callPackage ../packages/hdd-scraper { };
    list-iommu = prev.callPackage ../packages/list-iommu { };
    luks-backup = prev.callPackage ../packages/luks-backup { };
    pi-extensions = prev.callPackage ../packages/pi-extensions { };
    process-anime = prev.callPackage ../packages/process-anime { };
    prometheus-smartctl = prev.callPackage ../packages/prometheus-smartctl { };
    qbit-manager = prev.callPackage ../packages/qbit-manager { };
    radarr-cleanup = prev.callPackage ../packages/radarr-cleanup { };
    sonarr-anime-cleanup = prev.callPackage ../packages/sonarr-anime-cleanup { };
    sonarr-cleanup = prev.callPackage ../packages/sonarr-cleanup { };
    sorter = prev.callPackage ../packages/sorter { };

    bun = final.unstable.bun;
    cloudflared = final.unstable.cloudflared;
    ghostty-bin = final.unstable.ghostty-bin;
    hydrus = final.unstable.hydrus.overrideAttrs (oldAttrs: {
      doCheck = false;
      doInstallCheck = false;
      propagatedBuildInputs = builtins.filter (
        dep: dep != final.python3Packages.psd-tools
      ) oldAttrs.propagatedBuildInputs;
    });
    lmstudio = final.unstable.lmstudio;
  };
}
