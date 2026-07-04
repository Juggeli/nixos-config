{
  flake.homeModules.claude-code =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      hmLib = inputs.home-manager.lib;
      claude-code = inputs.llm-agents.packages.${pkgs.system}.claude-code;
      homeDir = if pkgs.stdenv.isDarwin then "/Users/juggeli" else "/home/juggeli";
      configFile = "${homeDir}/.claude/settings.json";

      managedSettings = {
        alwaysThinkingEnabled = true;
        cleanupPeriodDays = 99999;
        includeCoAuthoredBy = false;
        gitAttribution = false;
      };
      removedUserPromptContextHook = {
        type = "command";
        command = "~/.claude/hooks/user_prompt_context.sh";
        timeout = 5;
      };

      patchClaudeSettings = pkgs.writeShellScript "patch-claude-settings" ''
        CONFIG_FILE="${configFile}"
        MANAGED_SETTINGS='${builtins.toJSON managedSettings}'
        REMOVED_USER_PROMPT_CONTEXT_HOOK='${builtins.toJSON removedUserPromptContextHook}'

        mkdir -p "$(dirname "$CONFIG_FILE")"

        if [ ! -f "$CONFIG_FILE" ]; then
          echo "{}" > "$CONFIG_FILE"
        fi

        ${pkgs.jq}/bin/jq \
          --argjson managed "$MANAGED_SETTINGS" \
          --argjson removedHook "$REMOVED_USER_PROMPT_CONTEXT_HOOK" \
          'del(.hooks.UserPromptSubmit[]? | select(.hooks == [$removedHook]))
            | if (.hooks.UserPromptSubmit? == []) then del(.hooks.UserPromptSubmit) else . end
            | if (.hooks? == {}) then del(.hooks) else . end
            | . * $managed' \
          "$CONFIG_FILE" > "$CONFIG_FILE.tmp" \
          && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      '';
    in
    {
      home-manager.users.juggeli = {
        home.packages = [
          claude-code
          (pkgs.writeShellScriptBin "ccg" ''
            ZAI_TOKEN=$(cat ${config.age.secrets.zai-api-key.path})
            exec ${claude-code}/bin/claude --settings '{"env": {"ANTHROPIC_AUTH_TOKEN": "'"$ZAI_TOKEN"'", "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic", "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air", "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7", "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7"}}' "$@"
          '')
        ];
        home.shellAliases.cc = "claude --dangerously-skip-permissions";

        home.activation.patchClaudeSettings = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${patchClaudeSettings}
        '';
      };
    };
}
