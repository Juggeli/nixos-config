{
  flake.homeModules.claude-code =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      hmLib = inputs.home-manager.lib;
      claude-code = inputs.llm-agents.packages.${pkgs.system}.claude-code;
      homeDir = if pkgs.stdenv.isDarwin then "/Users/juggeli" else "/home/juggeli";
      configDir = "${homeDir}/src/dotfiles/modules/home/claude-code";
    in
    {
      home-manager.users.juggeli = {
        home.packages = [ claude-code ];
        home.shellAliases.cc = "claude --dangerously-skip-permissions";

        # Symlink config directly into the repo so Claude Code can edit it at
        # runtime while the files stay tracked. Must be a single-hop symlink
        # (not home.file/mkOutOfStoreSymlink): Claude Code's settings writer
        # resolves one symlink level and writes a temp file next to the
        # target, which fails on the read-only store hop.
        home.activation.linkClaudeConfig = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${homeDir}/.claude"
          ln -sfn "${configDir}/settings.json" "${homeDir}/.claude/settings.json"
          ln -sfn "${configDir}/CLAUDE.md" "${homeDir}/.claude/CLAUDE.md"
        '';

        # enabledPlugins in settings.json only marks intent; fetching the
        # plugin still needs a one-time install per machine. The activation
        # unit's PATH lacks git, which claude needs to clone the marketplace.
        home.activation.installClaudePlugins = hmLib.hm.dag.entryAfter [ "linkClaudeConfig" ] ''
          if ! grep -q "safety-net@cc-marketplace" "${homeDir}/.claude/plugins/installed_plugins.json" 2>/dev/null; then
            PATH="${pkgs.git}/bin:$PATH" ${claude-code}/bin/claude plugin marketplace add https://github.com/kenryu42/cc-marketplace || true
            PATH="${pkgs.git}/bin:$PATH" ${claude-code}/bin/claude plugin install safety-net@cc-marketplace || true
          fi
        '';
      };
    };
}
