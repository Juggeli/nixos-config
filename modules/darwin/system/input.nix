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

      # Karabiner-Elements for caps lock mapping
      homebrew.casks = [ "karabiner-elements" ];

      plusultra.home.configFile."karabiner/karabiner.json".text = builtins.toJSON {
        global = {
          check_for_updates_on_startup = true;
          show_in_menu_bar = true;
          show_profile_name_in_menu_bar = false;
        };
        profiles = [
          {
            name = "Default profile";
            selected = true;
            virtual_hid_keyboard = {
              country_code = 0;
              keyboard_type_v2 = "ansi";
            };
            complex_modifications = {
              parameters = {
                basic = {
                  simultaneous_threshold_milliseconds = 50;
                  to_delayed_action_delay_milliseconds = 500;
                  to_if_alone_timeout_milliseconds = 1000;
                  to_if_held_down_threshold_milliseconds = 500;
                };
                mouse_motion_to_scroll = {
                  speed = 100;
                };
              };
              rules = [
                {
                  description = "Change caps_lock to command+control+option+shift if pressed with other keys, to escape if pressed alone.";
                  manipulators = [
                    {
                      from = {
                        key_code = "caps_lock";
                        modifiers = {
                          optional = [ "any" ];
                        };
                      };
                      to = [
                        {
                          key_code = "left_control";
                        }
                      ];
                      to_if_alone = [
                        {
                          key_code = "escape";
                        }
                      ];
                      type = "basic";
                    }
                  ];
                }
              ];
            };
          }
        ];
      };
    }
  ]);
}
