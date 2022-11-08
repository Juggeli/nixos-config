{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.shell.fish;
in
{
  options.modules.shell.fish = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    users.defaultUserShell = pkgs.fish;

    hm.programs.fish = {
      enable = true;
      shellAbbrs = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        clr = "clear";
        rm = "rm -i";
        cp = "cp -i";
        mv = "mv -i";
        mkdir = "mkdir -pv";
        ports = "netstat -tulanp";
        shutdown = "sudo shutdown";
        reboot = "sudo reboot";
        jc = "journalctl -xe";
        sc = "systemctl";
        ssc = "sudo systemctl";
        exa = "exa --group-directories-first --git";
        l = "exa -blF";
        ls = "exa -blF";
        ll = "exa -abghilmu";
        llm = "ll --sort=modified";
        la = "LC_COLLATE=C exa -ablF";
        tree = "exa --tree";
        cat = "bat";
        nixsw = "sudo nixos-rebuild switch --flake .#";
        nixup = "sudo nixos-rebuild switch --flake .# --recreate-lock-file";
      };
      plugins = [
        { name = "grc"; src = pkgs.fishPlugins.grc.src; }
        { name = "autopair-fish"; src = pkgs.fishPlugins.autopair-fish.src; }
        { name = "pure"; src = pkgs.fishPlugins.pure.src; }
        {
          name = "z";
          src = pkgs.fetchFromGitHub {
            owner = "jethrokuan";
            repo = "z";
            rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
            sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
          };
        }
      ];
    };
  };
}
