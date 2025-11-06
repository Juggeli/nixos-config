{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.ai-agents;
in
{
  options.plusultra.cli-apps.ai-agents = with types; {
    enable = mkBoolOpt false "Whether or not to enable ai-agents.";
    ccg = {
      enable = mkBoolOpt false "Whether or not to enable ccg wrapper for z.ai.";
      secretPath = mkOpt types.path null "Path to the zai.age secret file.";
    };
    ccm = {
      enable = mkBoolOpt false "Whether or not to enable ccm wrapper for minimax.";
      secretPath = mkOpt types.path null "Path to the minimax.age secret file.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = with pkgs; [
        claude-code
        codex
        uv
        nodejs
        gemini-cli
        opencode
      ];
      plusultra.user.impermanence = {
        directories = [
          ".cache/opencode"
          ".claude"
          ".local/share/uv"
          ".cache/uv"
          ".codex"
          ".config/claude"
          ".config/opencode"
          ".gemini"
          ".local/share/opencode"
          ".local/state/opencode"
        ];
        files = [
          ".claude.json"
        ];
      };
    })

    (mkIf (cfg.enable && cfg.ccg.enable) {
      age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

      age.secrets.zai = {
        file = cfg.ccg.secretPath;
      };

      home.packages = with pkgs; [
        (pkgs.writeShellScriptBin "ccg" ''
          ZAI_TOKEN=$(cat ${config.age.secrets.zai.path})
          exec ${pkgs.claude-code}/bin/claude --settings "{\"env\": {\"ANTHROPIC_AUTH_TOKEN\": \"$ZAI_TOKEN\",\"ANTHROPIC_BASE_URL\": \"https://api.z.ai/api/anthropic\"}}" "$@"
        '')
      ];
    })

    (mkIf (cfg.enable && cfg.ccm.enable) {
      age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

      age.secrets.minimax = {
        file = cfg.ccm.secretPath;
      };

      home.packages = with pkgs; [
        (pkgs.writeShellScriptBin "ccm" ''
          MINIMAX_TOKEN=$(cat ${config.age.secrets.minimax.path})
          exec ${pkgs.claude-code}/bin/claude --settings "{\"env\": {\"ANTHROPIC_BASE_URL\": \"https://api.minimax.io/anthropic\",\"ANTHROPIC_AUTH_TOKEN\": \"$MINIMAX_TOKEN\",\"API_TIMEOUT_MS\": \"3000000\",\"CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC\": \"1\",\"ANTHROPIC_MODEL\": \"MiniMax-M2\",\"ANTHROPIC_SMALL_FAST_MODEL\": \"MiniMax-M2\",\"ANTHROPIC_DEFAULT_SONNET_MODEL\": \"MiniMax-M2\",\"ANTHROPIC_DEFAULT_OPUS_MODEL\": \"MiniMax-M2\",\"ANTHROPIC_DEFAULT_HAIKU_MODEL\": \"MiniMax-M2\"}}" "$@"
        '')
      ];
    })
  ];
}
