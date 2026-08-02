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
      };
    };
}
