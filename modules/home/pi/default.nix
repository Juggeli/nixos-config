{
  flake.homeModules.pi =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      hmLib = inputs.home-manager.lib;
      llm-agents = inputs.llm-agents.packages.${pkgs.system};
      homeDir = if pkgs.stdenv.isDarwin then "/Users/juggeli" else "/home/juggeli";
      agentDir = "${homeDir}/.pi/agent";
      modelsConfigFile = "${agentDir}/models.json";
      openRouterDeepSeekRouting = {
        order = [ "deepseek" ];
        allow_fallbacks = true;
      };
      openRouterDeepSeekModels = [
        "deepseek/deepseek-chat"
        "deepseek/deepseek-chat-v3-0324"
        "deepseek/deepseek-chat-v3.1"
        "deepseek/deepseek-r1"
        "deepseek/deepseek-r1-0528"
        "deepseek/deepseek-v3.1-terminus"
        "deepseek/deepseek-v3.2"
        "deepseek/deepseek-v3.2-exp"
        "deepseek/deepseek-v4-flash"
        "deepseek/deepseek-v4-pro"
      ];
      openRouterDeepSeekModelOverrides = builtins.listToAttrs (
        map (id: {
          name = id;
          value.compat.openRouterRouting = openRouterDeepSeekRouting;
        }) openRouterDeepSeekModels
      );
      patchPiModels = pkgs.writeShellScript "patch-pi-models" ''
        CONFIG_FILE="${modelsConfigFile}"
        MANAGED_OVERRIDES='${builtins.toJSON openRouterDeepSeekModelOverrides}'
        OPENROUTER_DEEPSEEK_ROUTING='${builtins.toJSON openRouterDeepSeekRouting}'

        mkdir -p "$(dirname "$CONFIG_FILE")"

        if [ ! -f "$CONFIG_FILE" ]; then
          echo '{"providers":{}}' > "$CONFIG_FILE"
        fi

        ${pkgs.jq}/bin/jq \
          --argjson managedOverrides "$MANAGED_OVERRIDES" \
          --argjson routing "$OPENROUTER_DEEPSEEK_ROUTING" \
          '.providers //= {}
            | .providers.openrouter //= {}
            | .providers.openrouter.modelOverrides = ((.providers.openrouter.modelOverrides // {}) * $managedOverrides)
            | reduce (if (.providers.openrouter.models | type) == "array" then .providers.openrouter.models[] else empty end | select(((.id // "") | startswith("deepseek/"))) | .id) as $id
                (. ; .providers.openrouter.modelOverrides[$id].compat.openRouterRouting = $routing)
            | if ((.providers.openrouter.models // null) | type) == "array" then
                .providers.openrouter.models |= map(
                  if ((.id // "") | startswith("deepseek/")) then
                    .compat = ((.compat // {}) * { openRouterRouting: $routing })
                  else
                    .
                  end
                )
              else
                .
              end' \
          "$CONFIG_FILE" > "$CONFIG_FILE.tmp" \
          && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      '';
      patchPiSyntheticConfig = pkgs.writeShellScript "patch-pi-synthetic-config" ''
        CONFIG_FILE="${agentDir}/extensions/synthetic.json"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        if [ ! -f "$CONFIG_FILE" ]; then
          echo '{}' > "$CONFIG_FILE"
        fi
        ${pkgs.jq}/bin/jq '.webSearch = false' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" \
          && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      '';
      # The default bun-compiled binary lacks node:sqlite, which
      # pi-hashline-edit-pro's hash store needs; the npm package's official
      # Node entry point (Node >= 22.5) provides it.
      pi = llm-agents.pi.override { useBun = false; };
      configDir = "${homeDir}/src/dotfiles/modules/home/pi";
      localExtensionsDir = "${homeDir}/src/dotfiles/packages/pi-extensions/packages";
      # Third-party extensions are installed imperatively via `pi install`,
      # which resolves node_modules itself under ~/.pi/agent/npm. Pinned here;
      # the resulting settings.json entries land in the repo-tracked file.
      npmExtensions = [
        {
          name = "pi-hashline-edit-pro";
          version = "1.0.0";
        }
        {
          name = "cc-safety-net";
          version = "1.0.6";
        }
        {
          name = "pi-rtk-optimizer";
          version = "0.9.0";
        }
      ];
      installPiExtensions = pkgs.writeShellScript "install-pi-extensions" ''
        export PATH="${pkgs.nodejs}/bin:$PATH"
        ensure() {
          local name="$1" version="$2"
          local pkgJson="${agentDir}/npm/node_modules/$name/package.json"
          if [ "$(${pkgs.jq}/bin/jq -r .version "$pkgJson" 2>/dev/null)" != "$version" ]; then
            ${pi}/bin/pi install "npm:$name@$version" || true
          fi
        }
        ${lib.concatMapStringsSep "\n" (e: ''ensure "${e.name}" "${e.version}"'') npmExtensions}
      '';
    in
    {
      # Locally authored extensions are symlinked out of the store so edits in
      # the repo take effect on the next pi session without a rebuild.
      home-manager.users.juggeli = hmArgs: {
        home.packages = [
          (pkgs.writeShellScriptBin "pi" ''
            export PI_AGENT_DIR="${agentDir}"
            set -a
            source ${config.age.secrets.agent-env.path}
            set +a
            export CC_SAFETY_NET_STRICT=1
            export CC_SAFETY_NET_PARANOID_RM=1
            exec ${pi}/bin/pi "$@"
          '')
          pkgs.unstable.rtk
          pkgs.nodejs
        ];

        home.file.".pi/agent/AGENTS.md".text = ''
          ## Style

          Respond like smart caveman. Cut all filler, keep technical substance.

          - Drop articles (a, an, the), filler (just, really, basically, actually).
          - Drop pleasantries (sure, certainly, happy to).
          - No hedging. Fragments fine. Short synonyms.
          - Technical terms stay exact. Code blocks unchanged.
          - Pattern: [thing] [action] [reason]. [next step].

          ## Secrets

          Never print secret values (API keys, tokens, passwords, decrypted
          secrets) into the session; inspect them indirectly and keep them
          out of diffs and commits.
        '';
        home.file.".pi/agent/extensions/exa-tools".source =
          hmArgs.config.lib.file.mkOutOfStoreSymlink "${localExtensionsDir}/exa-tools";
        home.file.".pi/agent/extensions/file-search".source =
          hmArgs.config.lib.file.mkOutOfStoreSymlink "${localExtensionsDir}/file-search";
        home.file.".pi/agent/extensions/subagents-lite".source =
          hmArgs.config.lib.file.mkOutOfStoreSymlink "${localExtensionsDir}/subagents-lite";
        home.activation.patchPiModels = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${patchPiModels}
        '';
        # Home-manager renames in-the-way files to *.hm-backup when linking;
        # pi would load those copies as duplicate extensions and refuse the
        # real ones, so drop them.
        home.activation.cleanPiExtensionBackups = hmLib.hm.dag.entryAfter [ "linkGeneration" ] ''
          rm -rf "${agentDir}/extensions/"*.hm-backup
        '';
        home.activation.patchPiSyntheticConfig = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${patchPiSyntheticConfig}
        '';
        # Settings are symlinked into the repo so pi can write to them at
        # runtime (theme, default model, installed packages) while the file
        # stays tracked. Pi's settings writer follows symlinks, so no
        # single-hop workaround is needed; plain ln keeps it simple.
        home.activation.linkPiSettings = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${agentDir}"
          ln -sfn "${configDir}/settings.json" "${agentDir}/settings.json"
        '';
        home.activation.installPiExtensions = hmLib.hm.dag.entryAfter [ "linkPiSettings" ] ''
          ${installPiExtensions}
        '';
      };
    };
}
