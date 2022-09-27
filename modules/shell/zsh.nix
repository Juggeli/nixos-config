{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let 
  cfg = config.modules.shell.zsh;
  configDir = config.dotfiles.configDir;
in {
  options.modules.shell.zsh = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    users.defaultUserShell = pkgs.zsh;

    home.programs.zsh = {
      enable = true;
      shellAliases = {
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
        ls = "l";
        ll = "exa -abghilmu";
        llm = "ll --sort=modified";
        la = "LC_COLLATE=C exa -ablF";
        tree = "exa --tree";
        cat = "bat";
      };
      history = {
        size = 100000;
      };
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      plugins = [
        {
          # will source zsh-autosuggestions.plugin.zsh
          name = "zsh-autosuggestions";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-autosuggestions";
            rev = "v0.7.0";
            sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
          };
        }
      ];
    };

    home.programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };

    home.programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      historyWidgetOptions = ["--reverse"];
    };

    user.packages = with pkgs; [
      bat
      exa
      fd
      tldr
    ];
  };
}
