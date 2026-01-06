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
  configFile = "${config.home.homeDirectory}/.config/opencode/opencode.json";

  braveSearchWrapper = pkgs.writeShellScript "brave-search-mcp" ''
    export BRAVE_API_KEY="$(cat ${config.age.secrets.brave-api-key.path})"
    exec ${pkgs.nodejs}/bin/npx -y @brave/brave-search-mcp-server "$@"
  '';

  braveSearchMcp = {
    type = "local";
    command = [ "${braveSearchWrapper}" ];
  };

  patchOpencodeConfig = pkgs.writeShellScript "patch-opencode-config" ''
    CONFIG_FILE="${configFile}"

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "opencode.json not found, skipping brave-search MCP injection"
      exit 0
    fi

    if ${pkgs.jq}/bin/jq -e '.mcp."brave-search"' "$CONFIG_FILE" > /dev/null 2>&1; then
      echo "brave-search MCP already configured"
      exit 0
    fi

    echo "Adding brave-search MCP to opencode.json"
    ${pkgs.jq}/bin/jq '.mcp."brave-search" = ${builtins.toJSON braveSearchMcp}' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" \
      && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  '';
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

    home.activation.patchOpencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${patchOpencodeConfig}
    '';
  };
}
