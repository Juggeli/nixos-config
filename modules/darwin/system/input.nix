{ config, lib, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.system.input;
in
{
  options.plusultra.system.input = with types; {
    enable = mkEnableOption "macOS input";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      system = {
        defaults = {
          trackpad = {
            FirstClickThreshold = 0;
          };
          CustomUserPreferences = {
            "com.apple.symbolichotkeys" = {
              AppleSymbolicHotKeys = {
                "60" = {
                  # Disable '^ + Space' for selecting the previous input source
                  enabled = false;
                };
                "61" = {
                  # Disable '^ + Option + Space' for selecting the next input source
                  enabled = false;
                };
                # Disable 'Cmd + Space' for Spotlight Search
                "64" = {
                  enabled = false;
                };
                # Disable 'Cmd + Alt + Space' for Finder search window
                "65" = {
                  enabled = false;
                };
              };
            };
          };
          ".GlobalPreferences" = {
            "com.apple.mouse.scaling" = 1.0;
          };

          NSGlobalDomain = {
            AppleKeyboardUIMode = 3;
            ApplePressAndHoldEnabled = false;

            KeyRepeat = 2;
            InitialKeyRepeat = 15;

            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticSpellingCorrectionEnabled = false;
          };
        };
      };

      system.activationScripts.postActivation.text = ''
        # Following line should allow us to avoid a logout/login cycle when changing settings
        sudo -u ${config.plusultra.user.name} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

        # Reassign emoji picker shortcut from cmd+space to ctrl+shift+cmd+space
        sudo -u ${config.plusultra.user.name} defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Emoji & Symbols" "^\$@ "
      '';

      plusultra.home.extraOptions.home.activation = {
        # Disable special keys when using Option as a modifier.
        # https://superuser.com/questions/941286/disable-default-option-key-binding
        disableSpecialKeys = lib.home-manager.hm.dag.entryAfter [ "writeBoundary" ] ''
          set +e
          $DRY_RUN_CMD mkdir -p $HOME/Library/KeyBindings
          if [ ! -f "$HOME/Library/KeyBindings/DefaultKeyBinding.dict" ]; then
            $DRY_RUN_CMD cp '${builtins.toPath ./DefaultKeyBinding.dict}' "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
          fi
          set -e
        '';
      };
    }
  ]);
}
