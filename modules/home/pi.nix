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
      caveman = pkgs.fetchFromGitHub {
        owner = "jonjonrankin";
        repo = "pi-caveman";
        rev = "v1.0.7";
        hash = "sha256-DhawjQ6tZvG5go4ayPdB+Yup77MjsLF2hFmjxgu9yTQ=";
      };
      rtkOptimizer = pkgs.fetchFromGitHub {
        owner = "MasuRii";
        repo = "pi-rtk-optimizer";
        rev = "v0.9.0";
        hash = "sha256-Cw0oLzVv674vpC3g5oteCNZSkHpfBN+IdnYDbkai4q4=";
      };
      ccSafetyNet = pkgs.buildNpmPackage {
        pname = "cc-safety-net";
        version = "1.0.6";
        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/cc-safety-net/-/cc-safety-net-1.0.6.tgz";
          hash = "sha512-uc2EmRXPXb08cfN1eGnr+h3tWHqxA20fJGZoGBgW6wFl+Nubmmy6jug18vc7WrOW7dGBMPxz4VuU8srfjHtWlw==";
        };
        npmDepsHash = "sha256-P5IJcI3d30vTiiCorROWTdv9QpEZb8gh+bl/8uAFK7E=";
        postPatch = ''
          cp ${./cc-safety-net-package-lock.json} package-lock.json
          ${pkgs.jq}/bin/jq 'del(.devDependencies, .peerDependencies, .peerDependenciesMeta, .scripts.prepare)' \
            package.json > package.json.tmp
          mv package.json.tmp package.json
        '';
        dontNpmBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -R . $out/
          cat > $out/index.ts <<'EOF'
          export { default } from "./dist/pi/index.js";
          EOF
          runHook postInstall
        '';
      };
      piHashlineEdit = pkgs.buildNpmPackage {
        pname = "pi-hashline-edit";
        version = "0.8.3";
        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/pi-hashline-edit/-/pi-hashline-edit-0.8.3.tgz";
          hash = "sha512-eQWvwvR8aS7e/8CLTt8sdGhFXJguPTyFK+m9IB2muQQHsPnyMlF/cXKzEo5mQ898LxAM1jl7UVhPsmNXR8y/Mw==";
        };
        npmDepsHash = "sha256-bOND42nfLErqPELQ5SjC0ChqgEn1j8ySnDymR+LoJ4U=";
        postPatch = ''
          cp ${./pi-hashline-edit-package-lock.json} package-lock.json
          ${pkgs.jq}/bin/jq 'del(.devDependencies, .peerDependencies, .scripts)' \
            package.json > package.json.tmp
          mv package.json.tmp package.json
        '';
        dontNpmBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -R . $out/
          runHook postInstall
        '';
      };
      filterTests =
        src:
        lib.cleanSourceWith {
          inherit src;
          filter = path: _type: !(builtins.baseNameOf path == "__tests__");
        };
      extensionsSource = pkgs.runCommand "pi-agent-extensions" { } ''
        mkdir -p $out
        cp -R ${filterTests ../../packages/pi-extensions/packages}/. $out/
        cp -R ${caveman}/. $out/pi-caveman
        cp -R ${rtkOptimizer}/. $out/pi-rtk-optimizer
        cp -R ${ccSafetyNet}/. $out/cc-safety-net
        cp -R ${piHashlineEdit}/. $out/pi-hashline-edit
      '';
      pi = llm-agents.pi;
    in
    {
      home-manager.users.juggeli = {
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

        home.file.".pi/agent/extensions" = {
          source = extensionsSource;
          recursive = true;
        };
        home.file.".pi/agent/hashline.json".text = builtins.toJSON {
          grep = true;
        };
        home.activation.patchPiModels = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${patchPiModels}
        '';
      };
    };
}
