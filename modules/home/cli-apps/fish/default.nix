{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.plusultra.cli-apps.fish;
in {
  options.plusultra.cli-apps.fish = {
    enable = mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grc
      eza
      bat
      lazygit
      fzf
    ];
    programs.fish = {
      enable = true;
      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        l = "eza -blF";
        ls = "eza -blF";
        ll = "eza -abghilmu";
        llm = "ll --sort=modified";
        la = "LC_COLLATE=C eza -ablF";
        cat = "bat";
        lg = "lazygit";
        s = "wezterm ssh";
      };
      shellAbbrs = {
        eza = "eza --group-directories-first --git";
        tree = "eza --tree";
      };
      interactiveShellInit =
        ''
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
        ''
        + builtins.readFile ./catpuccin.fish;
      plugins = [
        {
          name = "grc";
          src = pkgs.fishPlugins.grc.src;
        }
        {
          name = "autopair-fish";
          src = pkgs.fishPlugins.autopair-fish.src;
        }
        {
          name = "pure";
          src = pkgs.fishPlugins.pure.src;
        }
        {
          name = "z";
          src = pkgs.fetchFromGitHub {
            owner = "jethrokuan";
            repo = "z";
            rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
            sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
          };
        }
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
      ];
    };
  };
}
