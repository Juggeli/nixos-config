{
  flake.nixosModules.podman-soak =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.virtualisation.podmanImageSoak;

      # Every line needs its own terminator: `read` discards a trailing line that
      # is not newline-terminated, which would silently drop the last image.
      # The third column lists the units running the pinned tag: several
      # containers can share one image (sonarr-anime runs localhost/sonarr),
      # so the image key alone does not name what to restart.
      imageList = pkgs.writeText "podman-soak-images.tsv" (
        lib.concatStrings (
          lib.mapAttrsToList (
            name: ref:
            let
              units = map (n: "podman-${n}.service") (
                lib.attrNames (
                  lib.filterAttrs (
                    _: container: container.image == "localhost/${name}:pinned"
                  ) config.virtualisation.oci-containers.containers
                )
              );
            in
            "${name}\t${ref}\t${lib.concatStringsSep " " units}\n"
          ) cfg.images
        )
      );

      # Containers pinned to a local tag must not start before the tag exists,
      # which on a fresh host is only true after the first soak run.
      soakedUnits = map (name: "podman-${name}.service") (
        lib.attrNames (
          lib.filterAttrs (
            _: container: lib.hasPrefix "localhost/" container.image
          ) config.virtualisation.oci-containers.containers
        )
      );

      soakScript = pkgs.writeShellApplication {
        name = "podman-image-soak";
        runtimeInputs = with pkgs; [
          skopeo
          jq
          podman
          coreutils
          systemd
        ];
        text = ''
          state="$STATE_DIRECTORY/digests.json"
          [ -s "$state" ] || printf '{}' > "$state"

          now=$(date +%s)
          cutoff=$(( now - ${toString (cfg.soakDays * 86400)} ))
          problems=()

          while IFS=$'\t' read -r name ref units; do
            [ -n "$name" ] || continue

            # Reading the manifest costs a few KB and touches no layers, so the
            # digest history is free to keep for every tag we have ever seen.
            digest=""
            if manifest=$(skopeo inspect --no-tags "docker://$ref" 2>/dev/null); then
              digest=$(printf '%s' "$manifest" | jq -r '.Digest // empty')
            fi

            if [ -n "$digest" ]; then
              tmp=$(mktemp)
              jq --arg n "$name" --arg r "$ref" --arg d "$digest" --argjson t "$now" \
                '.[$n].ref = $r | .[$n].seen[$d] //= $t' "$state" > "$tmp"
              mv "$tmp" "$state"
            else
              echo "warn: could not read manifest for $ref"
              problems+=("$name: registry unreachable")
            fi

            # Newest digest that has finished soaking. Selecting on age rather
            # than on "is still current" is what stops a fast-moving upstream
            # from resetting the clock forever and freezing us on an old image.
            target=$(jq -r --arg n "$name" --argjson c "$cutoff" \
              '(.[$n].seen // {}) | to_entries | map(select(.value <= $c))
               | sort_by(.value) | last | .key // empty' "$state")

            pinned="localhost/$name:pinned"
            promoted=$(jq -r --arg n "$name" '.[$n].promoted // empty' "$state")

            # First run has no soaked digest yet and no local tag, so the
            # containers would have nothing to start from. Adopt what the tag
            # points at now; every later promotion goes through the soak.
            if [ -z "$target" ] && ! podman image exists "$pinned"; then
              target="$digest"
              [ -n "$target" ] && echo "bootstrap: adopting current $ref as $pinned"
            fi

            [ -n "$target" ] || continue
            if [ "$target" = "$promoted" ] && podman image exists "$pinned"; then
              continue
            fi

            # Pulling by digest rather than by tag is the whole point: it is the
            # image we soaked, not whatever the tag has moved on to since.
            if ! podman pull --quiet "$ref@$target" >/dev/null 2>&1; then
              echo "warn: could not pull $ref@$target"
              problems+=("$name: soaked digest no longer served, staying on current image")
              continue
            fi

            id=$(podman image inspect --format '{{.Id}}' "$ref@$target")
            podman tag "$id" "$pinned"

            tmp=$(mktemp)
            jq --arg n "$name" --arg d "$target" --argjson t "$now" \
              '.[$n].promoted = $d | .[$n].promotedAt = $t' "$state" > "$tmp"
            mv "$tmp" "$state"

            seen=$(jq -r --arg n "$name" --arg d "$target" '.[$n].seen[$d]' "$state")
            echo "promoted $name to $target (first seen $(( (now - seen) / 86400 ))d ago)"

            # Stopped units pick the new tag up on their next start; only
            # running ones are restarted. --no-block because this service is
            # ordered before the container units, so a synchronous restart
            # issued from inside it would deadlock during boot. Restarts
            # propagate through Requires=, so dependents like koto follow
            # their tailscale sidecar without being listed here.
            read -ra unitList <<< "$units"
            for unit in "''${unitList[@]}"; do
              if systemctl is-active --quiet "$unit"; then
                systemctl restart --no-block "$unit"
              fi
            done
          done < ${imageList}

          # A promotion leaves the previously pinned image untagged, and nothing
          # else cleans this user's storage, so unattended updates would grow it
          # without bound. Images still used by a running container are kept.
          podman image prune -f > /dev/null

          if [ ''${#problems[@]} -gt 0 ]; then
            printf '%s\n' "''${problems[@]}"
            ${lib.optionalString (cfg.notifyCommand != null) ''
              printf '%s\n' "''${problems[@]}" | ${pkgs.writeShellScript "podman-soak-notify" cfg.notifyCommand}
            ''}
          fi
        '';
      };
    in
    {
      options.virtualisation.podmanImageSoak = {
        enable = lib.mkEnableOption "delayed promotion of upstream container images";

        soakDays = lib.mkOption {
          type = lib.types.ints.positive;
          default = 3;
          description = ''
            How long a digest must have been published upstream before it is
            promoted. Trades timely security fixes against the window in which a
            compromised upstream image is publicly reported.
          '';
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = ''
            User the soak runs as. Point this at the user that owns the
            containers when they run rootless, so pulls and tags land in that
            user's image storage.
          '';
        };

        runtimeDir = lib.mkOption {
          type = lib.types.str;
          default = "/run/podman-image-soak";
          description = ''
            Directory used as XDG_RUNTIME_DIR, which podman derives its run
            root from. containers/storage expects every process sharing a
            graph root to also share its run root, so when the containers run
            rootless point this at the same directory their units use. The
            default is a private directory managed by the service; any other
            value must exist already.
          '';
        };

        images = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            plex = "ghcr.io/hotio/plex:latest";
          };
          description = ''
            Local tag name mapped to the upstream reference to track. Each entry
            is published locally as `localhost/<name>:pinned`, which is what
            containers should reference.
          '';
        };

        notifyCommand = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
          description = ''
            Shell snippet run with a description of any problems on stdin. Only
            invoked when a registry is unreachable or a soaked digest can no
            longer be pulled.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.podman-image-soak = {
          description = "Promote container images that have soaked upstream";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          before = soakedUnits;

          # Rootless podman execs the setuid newuidmap/newgidmap wrappers.
          path = [ "/run/wrappers" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe soakScript;
            StateDirectory = "podman-image-soak";
            User = cfg.user;
            # Without XDG_RUNTIME_DIR skopeo falls back to
            # /run/containers/$UID/auth.json, whose parent is root-only.
            RuntimeDirectory = lib.mkIf (cfg.runtimeDir == "/run/podman-image-soak") "podman-image-soak";
            Environment = [
              "HOME=${config.users.users.${cfg.user}.home}"
              "XDG_RUNTIME_DIR=${cfg.runtimeDir}"
            ];
            # Best effort: an unreachable registry must not hold up the
            # containers ordered after this, which keep their current image.
            SuccessExitStatus = [ 0 ];
          };
        };

        # Restarting the promoted units is the only root-side action a
        # non-root soak needs; grant exactly that rather than widening the
        # service itself.
        security.polkit = lib.mkIf (cfg.user != "root") {
          enable = true;
          extraConfig = ''
            polkit.addRule(function(action, subject) {
              if (action.id == "org.freedesktop.systemd1.manage-units" &&
                  subject.user == "${cfg.user}" &&
                  action.lookup("verb") == "restart" &&
                  /^podman-[0-9A-Za-z._:-]+\.service$/.test(action.lookup("unit"))) {
                return polkit.Result.YES;
              }
            });
          '';
        };

        # The 06:00 timer already exists for auto-update; promoting first means a
        # single run observes, promotes, and restarts whatever changed.
        systemd.services.podman-auto-update = {
          wants = [ "podman-image-soak.service" ];
          after = [ "podman-image-soak.service" ];
        };
      };
    };
}
