{ pkgs, ... }:

{
  services.getty.autologinUser = "juggeli";
  plusultra.home.extraOptions.programs.fish.loginShellInit = ''
    if test (tty) = /dev/tty1
      exec sway
    else
      exec ${pkgs.vlock}/bin/vlock
    end
  '';
}
