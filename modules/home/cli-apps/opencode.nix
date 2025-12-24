{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.opencode;
  secretsDir = ../../../homes/shared/secrets;

  braveSearchWrapper = pkgs.writeShellScript "brave-search-mcp" ''
    export BRAVE_API_KEY="$(cat ${config.age.secrets.brave-api-key.path})"
    exec ${pkgs.nodejs}/bin/npx -y @brave/brave-search-mcp-server "$@"
  '';

  mkModel =
    {
      id,
      name,
      reasoningEffort,
      reasoningSummary ? "auto",
      textVerbosity ? "medium",
    }:
    {
      ${id} = {
        inherit name;
        limit = {
          context = 272000;
          output = 128000;
        };
        modalities = {
          input = [
            "text"
            "image"
          ];
          output = [ "text" ];
        };
        options = {
          inherit reasoningEffort reasoningSummary textVerbosity;
          include = [ "reasoning.encrypted_content" ];
          store = false;
        };
      };
    };

  models = lib.foldl' (acc: model: acc // (mkModel model)) { } [
    {
      id = "gpt-5.2-none";
      name = "GPT 5.2 None (OAuth)";
      reasoningEffort = "none";
    }
    {
      id = "gpt-5.2-low";
      name = "GPT 5.2 Low (OAuth)";
      reasoningEffort = "low";
    }
    {
      id = "gpt-5.2-medium";
      name = "GPT 5.2 Medium (OAuth)";
      reasoningEffort = "medium";
    }
    {
      id = "gpt-5.2-high";
      name = "GPT 5.2 High (OAuth)";
      reasoningEffort = "high";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.2-xhigh";
      name = "GPT 5.2 Extra High (OAuth)";
      reasoningEffort = "xhigh";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.2-codex-low";
      name = "GPT 5.2 Codex Low (OAuth)";
      reasoningEffort = "low";
    }
    {
      id = "gpt-5.2-codex-medium";
      name = "GPT 5.2 Codex Medium (OAuth)";
      reasoningEffort = "medium";
    }
    {
      id = "gpt-5.2-codex-high";
      name = "GPT 5.2 Codex High (OAuth)";
      reasoningEffort = "high";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.2-codex-xhigh";
      name = "GPT 5.2 Codex Extra High (OAuth)";
      reasoningEffort = "xhigh";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.1-codex-max-low";
      name = "GPT 5.1 Codex Max Low (OAuth)";
      reasoningEffort = "low";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.1-codex-max-medium";
      name = "GPT 5.1 Codex Max Medium (OAuth)";
      reasoningEffort = "medium";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.1-codex-max-high";
      name = "GPT 5.1 Codex Max High (OAuth)";
      reasoningEffort = "high";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.1-codex-max-xhigh";
      name = "GPT 5.1 Codex Max Extra High (OAuth)";
      reasoningEffort = "xhigh";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.1-codex-low";
      name = "GPT 5.1 Codex Low (OAuth)";
      reasoningEffort = "low";
    }
    {
      id = "gpt-5.1-codex-medium";
      name = "GPT 5.1 Codex Medium (OAuth)";
      reasoningEffort = "medium";
    }
    {
      id = "gpt-5.1-codex-high";
      name = "GPT 5.1 Codex High (OAuth)";
      reasoningEffort = "high";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.1-codex-mini-medium";
      name = "GPT 5.1 Codex Mini Medium (OAuth)";
      reasoningEffort = "medium";
    }
    {
      id = "gpt-5.1-codex-mini-high";
      name = "GPT 5.1 Codex Mini High (OAuth)";
      reasoningEffort = "high";
      reasoningSummary = "detailed";
    }
    {
      id = "gpt-5.1-none";
      name = "GPT 5.1 None (OAuth)";
      reasoningEffort = "none";
    }
    {
      id = "gpt-5.1-low";
      name = "GPT 5.1 Low (OAuth)";
      reasoningEffort = "low";
      textVerbosity = "low";
    }
    {
      id = "gpt-5.1-medium";
      name = "GPT 5.1 Medium (OAuth)";
      reasoningEffort = "medium";
    }
    {
      id = "gpt-5.1-high";
      name = "GPT 5.1 High (OAuth)";
      reasoningEffort = "high";
      reasoningSummary = "detailed";
      textVerbosity = "high";
    }
  ];
in
{
  options.plusultra.cli-apps.opencode = with types; {
    enable = mkBoolOpt false "Whether or not to enable opencode.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
      nodejs
    ];

    age.secrets.brave-api-key.file = "${secretsDir}/brave-api-key.age";

    plusultra.user.impermanence = {
      directories = [
        ".cache/opencode"
        ".config/opencode"
        ".local/share/opencode"
        ".local/state/opencode"
      ];
    };

    home.file.".config/opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      plugin = [ "opencode-openai-codex-auth@4.2.0" ];
      provider = {
        openai = {
          options = {
            reasoningEffort = "medium";
            reasoningSummary = "auto";
            textVerbosity = "medium";
            include = [ "reasoning.encrypted_content" ];
            store = false;
          };
          inherit models;
        };
      };
      mcp = {
        brave-search = {
          type = "local";
          command = [ "${braveSearchWrapper}" ];
        };
      };
    };
  };
}
