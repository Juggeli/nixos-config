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
  configFile = "${config.home.homeDirectory}/.claude/settings.json";

  managedSettings = {
    alwaysThinkingEnabled = true;
    cleanupPeriodDays = 99999;
    includeCoAuthoredBy = false;
    gitAttribution = false;
  }
  // optionalAttrs (cfg.hooks != { }) { hooks = cfg.hooks; };

  patchClaudeSettings = pkgs.writeShellScript "patch-claude-settings" ''
    CONFIG_FILE="${configFile}"
    MANAGED_SETTINGS='${builtins.toJSON managedSettings}'

    mkdir -p "$(dirname "$CONFIG_FILE")"

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "{}" > "$CONFIG_FILE"
    fi

    ${pkgs.jq}/bin/jq --argjson managed "$MANAGED_SETTINGS" '. * $managed' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" \
      && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  '';
in
{
  options.plusultra.cli-apps.claude-code = with types; {
    enable = mkBoolOpt false "Whether or not to enable claude-code.";
    hooks = mkOpt (attrsOf anything) { } "Claude Code hooks configuration.";
    glm = {
      enable = mkBoolOpt true "Whether or not to enable glm wrapper for z.ai.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = with pkgs; [
        claude-code
      ];
      home.shellAliases.cc = "claude --dangerously-skip-permissions";
      plusultra.user.impermanence = {
        directories = [
          ".claude"
          ".config/claude"
        ];
        files = [
          ".claude.json"
        ];
      };
      plusultra.cli-apps.claude-code.hooks = {
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

      home.activation.patchClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${patchClaudeSettings}
      '';
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
          exec ${pkgs.claude-code}/bin/claude --settings '{"env": {"ANTHROPIC_AUTH_TOKEN": "'"$ZAI_TOKEN"'", "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic", "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air", "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7", "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7"}}' "$@"
        '')
      ];
    })
  ];
}
