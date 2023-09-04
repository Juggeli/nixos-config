{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
{
  plusultra.home.configFile = {
    "fish/functions/".source = ./fish;
  };

  programs.fish.enable = true;

  plusultra.home.extraOptions.programs.fish = {
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
      s = "wezterm ssh";
      vifm = "env TERM=kitty-direct vifm";
      haruka-unlock = "ssh root@haruka -p 22";
    };
    shellAbbrs = {
      clr = "clear";
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";
      mkdir = "mkdir -pv";
      ports = "netstat -tulanp";
      shutdown = "doas shutdown";
      reboot = "doas reboot";
      jc = "journalctl -xe";
      sc = "systemctl";
      ssc = "doas systemctl";
      exa = "exa --group-directories-first --git";
      tree = "exa --tree";
      nixsw = "doas nixos-rebuild switch --flake .#";
      nixup = "doas nixos-rebuild switch --flake .# --recreate-lock-file";
      fs = "flake switch";
      fu = "flake update";
    };
    interactiveShellInit = ''
      function bind_bang
        switch (commandline -t)
        case "!"
          commandline -t -- $history[1]
          commandline -f repaint
        case "*"
          commandline -i !
        end
      end

      function fish_user_key_bindings
        bind ! bind_bang
        bind \cY accept-autosuggestion execute
      end
    '' +
    readFile ./catpuccin.fish;
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
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
    ];
  };
}

