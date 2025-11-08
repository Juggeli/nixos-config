{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.user.agenix;

  # Function to read secrets.nix and extract secret names
  readSecretsFile =
    path:
    let
      secretsData = import path;
      secretNames = builtins.attrNames secretsData;
    in
    secretNames;

  # Get list of secrets from the secrets.nix file
  availableSecrets = readSecretsFile (cfg.secretsFile);

  # Filter secrets based on enabledSecrets list (if provided) or include all
  enabledSecrets =
    if cfg.enableAll then
      availableSecrets
    else
      builtins.filter (secret: builtins.elem secret cfg.enabledSecrets) availableSecrets;

  # Generate age.secrets configuration for each enabled secret
  secretConfigs = builtins.listToAttrs (
    map (secretName: {
      name = lib.strings.removeSuffix ".age" secretName;
      value = {
        file = "${cfg.secretsDirectory}/${secretName}";
      };
    }) enabledSecrets
  );
in
{
  options.plusultra.user.agenix = with types; {
    enable = mkBoolOpt false "Whether or not to enable agenix home secrets management.";

    identityPaths = mkOption {
      type = listOf str;
      default = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      description = "Paths to age identity files for decrypting secrets.";
    };

    secretsDirectory = mkOption {
      type = path;
      default = ../../../homes/shared/secrets;
      description = "Directory containing encrypted .age secret files.";
    };

    secretsFile = mkOption {
      type = path;
      default = ../../../homes/shared/secrets/secrets.nix;
      description = "Path to secrets.nix file containing secret definitions.";
    };

    enableAll = mkBoolOpt true "Whether to enable all secrets from the secrets file.";

    enabledSecrets = mkOption {
      type = listOf str;
      default = [ ];
      description = "List of specific secrets to enable (only used when enableAll = false).";
    };

    autoReload = mkBoolOpt false "Whether to automatically reload services when secrets change.";
  };

  config = mkIf cfg.enable {
    # Set age identity paths
    age.identityPaths = cfg.identityPaths;

    # Configure all enabled secrets
    age.secrets = secretConfigs;
  };
}
