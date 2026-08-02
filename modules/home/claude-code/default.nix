{
  flake.homeModules.claude-code =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      claude-code = inputs.llm-agents.packages.${pkgs.system}.claude-code;
      homeDir = if pkgs.stdenv.isDarwin then "/Users/juggeli" else "/home/juggeli";
      configDir = "${homeDir}/src/dotfiles/modules/home/claude-code";
    in
    {
      home-manager.users.juggeli =
        { config, ... }:
        {
          home.packages = [ claude-code ];
          home.shellAliases.cc = "claude --dangerously-skip-permissions";

          # Out-of-store symlinks so Claude Code can edit its own config at
          # runtime while the files stay tracked in this repo.
          home.file.".claude/settings.json".source =
            config.lib.file.mkOutOfStoreSymlink "${configDir}/settings.json";
          home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/CLAUDE.md";
        };
    };
}
