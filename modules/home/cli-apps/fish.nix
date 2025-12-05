{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.plusultra.cli-apps.fish;
  rebuildCommand = if pkgs.stdenv.isLinux then "nixos-rebuild" else "darwin-rebuild";
  sudoCommand = if pkgs.stdenv.isLinux then "doas" else "sudo";
in
{
  options.plusultra.cli-apps.fish = {
    enable = mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grc
      eza
      fzf
      dust
      gum
      (mkIf pkgs.stdenv.isLinux trashy)
      dua
      neofetch
      screen
      ripgrep
      zoxide
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
        la = "LC_COLLATE=C eza -ablF --group";
        cat = "bat";
        lg = "lazygit";
        docker = "podman";
        docker-compose = "podman-compose";
      };
      shellAbbrs = {
        eza = "eza --group-directories-first --git";
        tree = "eza --tree";
        nixsw =
          "${rebuildCommand} build --flake .# && ${sudoCommand} ${rebuildCommand} switch --flake .#"
          + lib.optionalString pkgs.stdenv.isLinux " --fast";
        nixup =
          "${rebuildCommand} build --flake .# --recreate-lock-file && ${sudoCommand} ${rebuildCommand} switch --flake .#"
          + lib.optionalString pkgs.stdenv.isLinux " --fast";
        nixed =
          "nvim && ${rebuildCommand} build --flake .# && ${sudoCommand} ${rebuildCommand} switch --flake .#"
          + lib.optionalString pkgs.stdenv.isLinux " --fast";
        scs = "doas systemctl start";
        scr = "doas systemctl restart";
        sce = "doas systemctl stop";
        scd = "doas systemctl status";
      };
      interactiveShellInit = ''
        # Auto-start tmux if not already inside tmux and in a terminal
        if status is-interactive; and not set -q TMUX; and test "$TERM_PROGRAM" != "vscode"
          tmux new-session -A -s main
        end

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
      '';
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
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
      ];
    };

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    catppuccin.fish.enable = true;

    plusultra.user.impermanence.directories = [
      ".local/share/fish"
      ".local/share/zoxide"
      ".cache/fish"
    ];
  };
}
