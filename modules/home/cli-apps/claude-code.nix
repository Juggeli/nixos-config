{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.claude-code;
in
{
  options.plusultra.cli-apps.claude-code = with types; {
    enable = mkBoolOpt false "Whether or not to enable claude-code.";
    glm = {
      enable = mkBoolOpt false "Whether or not to enable glm wrapper for z.ai.";
    };
    minimax = {
      enable = mkBoolOpt false "Whether or not to enable minimax wrapper for minimax.";
    };
    chutes = {
      enable = mkBoolOpt false "Whether or not to enable ccc wrapper for chutes.ai.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = with pkgs; [
        claude-code
      ];
      plusultra.user.impermanence = {
        directories = [
          ".claude"
          ".config/claude"
        ];
        files = [
          ".claude.json"
        ];
      };
      home.file.".claude/settings.json".text = builtins.toJSON {
        enabledPlugins = {
          "superpowers@superpowers-marketplace" = true;
        };
        alwaysThinkingEnabled = true;
        cleanupPeriodDays = 99999;
        includeCoAuthoredBy = false;
        gitAttribution = false;
        hooks = {
          UserPromptSubmit = [
            {
              hooks = [
                {
                  type = "command";
                  command = "~/.claude/hooks/user_prompt_context.py";
                  timeout = 5;
                }
              ];
            }
          ];
        };
      };
      home.file.".claude/hooks/user_prompt_context.py" = {
        text = ''
          #!/usr/bin/env python3
          import json
          import sys

          context = "Unless otherwise specified: DRY, YAGNI, KISS, Pragmatic. Ask questions for clarifications. When doing a plan or research-like request, present your findings and halt for confirmation. Use raggy first to find documentation. Speak the facts, don't sugar coat statements. Your opinion matters. End all responses with an emoji of an animal"

          response = {
              "hookSpecificOutput": {
                  "hookEventName": "UserPromptSubmit",
                  "additionalContext": context,
              }
          }

          print(json.dumps(response))
          sys.exit(0)
        '';
        executable = true;
      };
    })

    # Enable agenix for any AI provider that needs secrets
    (mkIf (cfg.enable && (cfg.glm.enable || cfg.minimax.enable || cfg.chutes.enable)) {
      plusultra.user.agenix = {
        enable = true;
        enabledSecrets =
          (optional cfg.glm.enable "zai.age")
          ++ (optional cfg.minimax.enable "minimax.age")
          ++ (optional cfg.chutes.enable "chutes.age");
        enableAll = false;
      };
    })

    # Create wrapper scripts for each provider
    (mkIf cfg.glm.enable {
      home.packages = with pkgs; [
        (pkgs.writeShellScriptBin "ccg" ''
          ZAI_TOKEN=$(cat ${config.age.secrets.zai.path})
          exec ${pkgs.claude-code}/bin/claude --settings '{"env": {"ANTHROPIC_AUTH_TOKEN": "'"$ZAI_TOKEN"'", "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic"}}' "$@"
        '')
      ];
    })

    (mkIf cfg.minimax.enable {
      home.packages = with pkgs; [
        (pkgs.writeShellScriptBin "ccm" ''
          MINIMAX_TOKEN=$(cat ${config.age.secrets.minimax.path})
          exec ${pkgs.claude-code}/bin/claude --settings '{"env": {"ANTHROPIC_BASE_URL": "https://api.minimax.io/anthropic", "ANTHROPIC_AUTH_TOKEN": "'"$MINIMAX_TOKEN"'", "API_TIMEOUT_MS": "3000000", "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1", "ANTHROPIC_MODEL": "MiniMax-M2", "ANTHROPIC_SMALL_FAST_MODEL": "MiniMax-M2", "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2", "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2", "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2"}}' "$@"
        '')
      ];
    })

    (mkIf cfg.chutes.enable {
      home.packages = with pkgs; [
        (pkgs.writeShellScriptBin "ccc" ''
          CHUTES_TOKEN=$(cat ${config.age.secrets.chutes.path})
          exec ${pkgs.claude-code}/bin/claude --settings '{"env": {"ANTHROPIC_AUTH_TOKEN": "'"$CHUTES_TOKEN"'", "ANTHROPIC_BASE_URL": "https://claude.chutes.ai", "API_TIMEOUT_MS": "6000000", "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"}}' "$@"
        '')
      ];
    })
  ];
}
