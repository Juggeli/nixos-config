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
      enable = mkBoolOpt true "Whether or not to enable glm wrapper for z.ai.";
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
                  command = "~/.claude/hooks/user_prompt_context.sh";
                  timeout = 5;
                }
              ];
            }
          ];
        };
      };
      home.file.".claude/hooks/user_prompt_context.sh" = {
        text = ''
          #!/usr/bin/env bash
          cat <<'EOF'
          {"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Unless otherwise specified: DRY, YAGNI, KISS, Pragmatic. Ask questions for clarifications. When doing a plan or research-like request, present your findings and halt for confirmation. Speak the facts, don't sugar coat statements. Your opinion matters. All your code will be reviewed by another AI agent. Shortcuts, simplifications, placeholders, fallbacks are not allowed. It's wasting time doing those because another AI agent will review and you'll have to redo. End all responses with an emoji of an animal"}}
          EOF
        '';
        executable = true;
      };
    })

    # Enable agenix for any AI provider that needs secrets
    (mkIf (cfg.enable && (cfg.glm.enable)) {
      plusultra.user.agenix = {
        enable = true;
        enabledSecrets = optional cfg.glm.enable "zai.age";
        enableAll = false;
      };
    })

    # Create wrapper scripts for each provider
    (mkIf cfg.glm.enable {
      home.packages = [
        (pkgs.writeShellScriptBin "ccg" ''
          ZAI_TOKEN=$(cat ${config.age.secrets.zai.path})
          exec ${pkgs.claude-code}/bin/claude --settings '{"env": {"ANTHROPIC_AUTH_TOKEN": "'"$ZAI_TOKEN"'", "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic"}}' "$@"
        '')
      ];
    })
  ];
}
