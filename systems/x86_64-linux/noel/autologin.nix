{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.cifs-utils
    (pkgs.writeShellScriptBin "lock" ''
      if [[ "$1" == this ]]
        then args="-s"
        else args="-san"
      fi
      USER=juggeli ${pkgs.vlock}/bin/vlock "$args"
    '')
  ];
  services.getty.autologinUser = "juggeli";
  programs.fish.loginShellInit = ''
    if test (tty) = /dev/tty1
      exec sway
    else
      doas /run/current-system/sw/bin/lock this
    end
  '';
}
