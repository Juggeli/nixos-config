{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
{
  plusultra.home.configFile = {
    "fish/functions/".source = ./fish;
  };

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
    };
    interactiveShellInit =
      # Open command buffer in vim when alt+e is pressed
      ''
        bind \ee edit_command_buffer
      '' +
      # kitty integration
      ''
        set --global KITTY_INSTALLATION_DIR "${pkgs.kitty}/lib/kitty"
        set --global KITTY_SHELL_INTEGRATION enabled
        source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
      '' +
      # Use vim bindings and cursors
      ''
        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block
      '';
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
}

