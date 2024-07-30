{ lib, ... }:
with lib.plusultra;
{
  plusultra = {
    roles.darwin-common = enabled;
  };

  environment.systemPath = [ "/opt/homebrew/bin" ];

  services.yabai.extraConfig = ''
    # Spaces
    yabai -m space 1 --label all
    yabai -m space 2 --label dev

    # Assign to spaces
    yabai -m rule --add app="Slack" space=all
    yabai -m rule --add app="Firefox" space=all
    yabai -m rule --add app="kitty" space=dev
    yabai -m rule --add app="Android Studio" space=all
    yabai -m rule --add app="XCode" space=all
  '';

  system.stateVersion = 4;
}
