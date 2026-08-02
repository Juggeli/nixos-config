{
  flake.homeModules.claude-code =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      claude-code = inputs.llm-agents.packages.${pkgs.system}.claude-code;
      homeDir = if pkgs.stdenv.isDarwin then "/Users/juggeli" else "/home/juggeli";
      configDir = "${homeDir}/src/dotfiles/modules/home/claude-code";
      agentEnv = config.age.secrets.agent-env.path;
    in
    {
      home-manager.users.juggeli =
        { config, ... }:
        {
          home.packages = [
            claude-code
            (pkgs.writeShellScriptBin "ccg" ''
              set -a
              source ${agentEnv}
              set +a
              ZAI_TOKEN=$ZAI_API_KEY
              exec ${claude-code}/bin/claude --settings '{"env": {"ANTHROPIC_AUTH_TOKEN": "'"$ZAI_TOKEN"'", "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic", "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air", "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7", "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7"}}' "$@"
            '')
          ];
          home.shellAliases.cc = "claude --dangerously-skip-permissions";

          # Out-of-store symlinks so Claude Code can edit its own config at
          # runtime while the files stay tracked in this repo.
          home.file.".claude/settings.json".source =
            config.lib.file.mkOutOfStoreSymlink "${configDir}/settings.json";
          home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/CLAUDE.md";
        };
    };
}
