{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.shell.fish;
  configDir = config.dotfiles.configDir;
in
{
  options.modules.shell.fish = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    users.defaultUserShell = pkgs.fish;

    hm.xdg.configFile = {
      "fish/functions/".source = "${configDir}/fish/";
    };

    hm.programs.fish = {
      enable = true;
      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        l = "exa -blF";
        ls = "exa -blF";
        ll = "exa -abghilmu";
        llm = "ll --sort=modified";
        la = "LC_COLLATE=C exa -ablF";
        cat = "bat";
        lg = "lazygit";
      };
      shellAbbrs = {
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
        tree = "exa --tree";
        nixsw = "sudo nixos-rebuild switch --flake .#";
        nixup = "sudo nixos-rebuild switch --flake .# --recreate-lock-file";
      };
      shellInit = ''
        function __history_previous_command
          switch (commandline -t)
          case "!"
            commandline -t $history[1]; commandline -f repaint
          case "*"
            commandline -i !
          end
        end

        function __history_previous_command_arguments
          switch (commandline -t)
          case "!"
            commandline -t ""
            commandline -f history-token-search-backward
          case "*"
            commandline -i '$'
          end
        end

        bind ! __history_previous_command
        bind '$' __history_previous_command_arguments

        set fish_vi_key_bindings
      '';
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
