{
  flake.nixosModules.haruka-arr-api-keys =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      runtimeDir = "/run/arr-api-keys";

      # Each key lives in exactly one agenix secret. Sonarr and Radarr read
      # theirs from the environment, which takes precedence over config.xml, so
      # rotating a key means editing the secret and restarting the container.
      # homepageVar is the name homepage expects for that same key.
      services = {
        sonarr = {
          secret = "sonarr-api";
          envVar = "SONARR__AUTH__APIKEY";
          homepageVar = "HOMEPAGE_VAR_SONARR_API_KEY";
        };
        sonarr-anime = {
          secret = "sonarr-anime-api";
          envVar = "SONARR__AUTH__APIKEY";
          homepageVar = "HOMEPAGE_VAR_SONARR_ANIME_API_KEY";
        };
        radarr = {
          secret = "radarr-api";
          envVar = "RADARR__AUTH__APIKEY";
          homepageVar = "HOMEPAGE_VAR_RADARR_API_KEY";
        };
        radarr-anime = {
          secret = "radarr-anime-api";
          envVar = "RADARR__AUTH__APIKEY";
          homepageVar = "HOMEPAGE_VAR_RADARR_ANIME_API_KEY";
        };
      };

      secretPath = name: config.age.secrets.${services.${name}.secret}.path;

      # The container env files are read by podman running as the oci user,
      # so they are owned by it behind a traverse-only directory.
      renderService = name: svc: ''
        install -m 0400 -o oci /dev/null ${runtimeDir}/${name}.env
        printf '%s=%s\n' ${svc.envVar} "$(cat ${secretPath name})" > ${runtimeDir}/${name}.env
      '';

      homepageLine = name: svc: ''
        printf '%s=%s\n' ${svc.homepageVar} "$(cat ${secretPath name})" >> ${runtimeDir}/homepage.env
      '';

      consumers = (lib.mapAttrs' (name: _: lib.nameValuePair "podman-${name}" { }) services) // {
        homepage-dashboard = { };
      };
    in
    {
      systemd.services = {
        arr-api-keys = {
          description = "Render *arr API keys into environment files";
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            RuntimeDirectory = "arr-api-keys";
            RuntimeDirectoryMode = "0711";
            RuntimeDirectoryPreserve = "yes";
            UMask = "0077";
          };

          path = [ pkgs.coreutils ];

          script = ''
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderService services)}

            # homepage wants every HOMEPAGE_VAR_* in a single file, so the *arr
            # keys are appended to the entries still kept in homepage-env.
            install -m 0400 /dev/null ${runtimeDir}/homepage.env
            cat ${config.age.secrets.homepage-env.path} > ${runtimeDir}/homepage.env
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList homepageLine services)}
          '';
        };
      }
      // lib.mapAttrs (_: _: {
        after = [ "arr-api-keys.service" ];
        requires = [ "arr-api-keys.service" ];
      }) consumers;

      services.homepage-dashboard.environmentFile = "${runtimeDir}/homepage.env";

      virtualisation.oci-containers.containers = lib.mapAttrs (name: _: {
        environmentFiles = [ "${runtimeDir}/${name}.env" ];
      }) services;
    };
}
