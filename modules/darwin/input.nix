{
  flake.darwinModules.input =
    { inputs, ... }:
    {
      system = {
        defaults = {
          trackpad = {
            FirstClickThreshold = 0;
          };
          CustomUserPreferences = {
            "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
              TrackpadThreeFingerVertSwipeGesture = 0;
              TrackpadFourFingerVertSwipeGesture = 0;
            };
            "com.apple.AppleMultitouchTrackpad" = {
              TrackpadThreeFingerVertSwipeGesture = 0;
              TrackpadFourFingerVertSwipeGesture = 0;
            };
            "com.apple.symbolichotkeys" = {
              AppleSymbolicHotKeys = {
                "60" = {
                  enabled = false;
                };
                "61" = {
                  enabled = false;
                };
                "64" = {
                  enabled = false;
                };
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

        activationScripts.postActivation.text = ''
          sudo -u juggeli /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

          sudo -u juggeli defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Emoji & Symbols" "^\$@ "
        '';
      };

      homebrew.casks = [ "karabiner-elements" ];

      home-manager.users.juggeli = {
        home.activation.disableSpecialKeys =
          inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
            ''
              set +e
              $DRY_RUN_CMD mkdir -p $HOME/Library/KeyBindings
              if [ ! -f "$HOME/Library/KeyBindings/DefaultKeyBinding.dict" ]; then
                $DRY_RUN_CMD cp '${./_DefaultKeyBinding.dict}' "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
              fi
              set -e
            '';

        xdg.configFile."karabiner/karabiner.json".text = builtins.toJSON {
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
      };
    };
}
