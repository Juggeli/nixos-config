{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.letta;
  secretsDir = "/mnt/appdata/letta/secrets";
  streamPatch = ./letta-stream-patch.py;
in
{
  options.plusultra.containers.letta = with types; {
    enable = mkBoolOpt false "Whether or not to enable Letta service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Letta";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "AI agent platform";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "letta.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "AI";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 8283;
        description = "Port for homepage link";
      };
    };
    environment = {
      openaiApiKeyFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing OpenAI API key (used for embeddings if openrouterApiKeyFile is set)";
      };
      openaiApiBaseUrl = mkOption {
        type = nullOr str;
        default = "https://api.synthetic.new/openai/v1";
        description = "OpenAI API base URL";
      };
      openrouterApiKeyFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing OpenRouter API key (for LLM models)";
      };
      anthropicApiKeyFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing Anthropic API key";
      };
      ollamaBaseUrl = mkOption {
        type = nullOr str;
        default = null;
        description = "Ollama base URL for local models and embeddings";
      };
      secure = mkOption {
        type = bool;
        default = false;
        description = "Enable password protection";
      };
      passwordFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing server password";
      };
      e2bApiKeyFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing E2B API key for tool sandboxing";
      };
      e2bSandboxTemplateId = mkOption {
        type = nullOr str;
        default = null;
        description = "E2B sandbox template ID for tool sandboxing";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environment.secure -> (cfg.environment.passwordFile != null);
        message = "Letta: passwordFile must be set when secure mode is enabled";
      }
    ];

    systemd.services.letta-secrets = {
      description = "Generate Letta environment file from secrets";
      wantedBy = [ "podman-letta.service" ];
      before = [ "podman-letta.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p ${secretsDir}
        chmod 700 ${secretsDir}

        {
          echo "SECURE=${if cfg.environment.secure then "true" else "false"}"
          ${optionalString (cfg.environment.openaiApiKeyFile != null) ''
            echo "OPENAI_API_KEY=$(cat ${cfg.environment.openaiApiKeyFile})"
          ''}
          ${optionalString (cfg.environment.openaiApiBaseUrl != null) ''
            echo "OPENAI_API_BASE=${cfg.environment.openaiApiBaseUrl}"
          ''}
          ${optionalString (cfg.environment.openrouterApiKeyFile != null) ''
            echo "OPENROUTER_API_KEY=$(cat ${cfg.environment.openrouterApiKeyFile})"
          ''}
          ${optionalString (cfg.environment.anthropicApiKeyFile != null) ''
            echo "ANTHROPIC_API_KEY=$(cat ${cfg.environment.anthropicApiKeyFile})"
          ''}
          ${optionalString (cfg.environment.ollamaBaseUrl != null) ''
            echo "OLLAMA_BASE_URL=${cfg.environment.ollamaBaseUrl}"
          ''}
          ${optionalString (cfg.environment.passwordFile != null) ''
            echo "LETTA_SERVER_PASSWORD=$(cat ${cfg.environment.passwordFile})"
          ''}
          ${optionalString (cfg.environment.e2bApiKeyFile != null) ''
            echo "E2B_API_KEY=$(cat ${cfg.environment.e2bApiKeyFile})"
          ''}
          ${optionalString (cfg.environment.e2bSandboxTemplateId != null) ''
            echo "E2B_SANDBOX_TEMPLATE_ID=${cfg.environment.e2bSandboxTemplateId}"
          ''}
        } > ${secretsDir}/letta.env

        chmod 600 ${secretsDir}/letta.env
      '';
    };

    systemd.services.podman-letta = {
      after = [ "letta-secrets.service" ];
      requires = [ "letta-secrets.service" ];
    };

    virtualisation.oci-containers.containers.letta = {
      image = "docker.io/letta/letta:latest";
      autoStart = true;
      ports = [ "8283:8283" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      volumes = [
        "/mnt/appdata/letta/pgdata:/var/lib/postgresql/data"
        "${streamPatch}:/opt/letta-patches/sitecustomize.py:ro"
      ];
      environment = {
        PYTHONPATH = "/opt/letta-patches";
      };
      environmentFiles = [ "${secretsDir}/letta.env" ];
    };
  };
}
