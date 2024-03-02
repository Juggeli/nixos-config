{ lib, config, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.plusultra.cli-apps.fish;
  rebuildCommand = if pkgs.stdenv.isLinux then "doas nixos-rebuild" else "darwin-rebuild";
in
{
  options.plusultra.cli-apps.fish = {
    enable = mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grc
      eza
      bat
      fzf
      du-dust
      gum
      (mkIf pkgs.stdenv.isLinux trashy)
      dua
      neofetch
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
        s = "kitten ssh";
        ssh = "kitten ssh";
      };
      shellAbbrs = {
        eza = "eza --group-directories-first --git";
        tree = "eza --tree";
        nixsw = rebuildCommand + " switch --flake .#";
        nixup = rebuildCommand + " switch --flake .# --recreate-lock-file";
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

          function ya
            set tmp (mktemp -t "yazi-cwd.XXXXX")
            yazi $argv --cwd-file="$tmp"
            if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
              cd -- "$cwd"
            end
            rm -f -- "$tmp"
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
          src = pkgs.fishPlugins.z.src;
        }
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
      ];
    };

    plusultra.user.impermanence.directories = mkIf config.plusultra.user.impermanence.enable [
      ".local/share/fish"
      ".local/share/z"
    ];
  };
}
