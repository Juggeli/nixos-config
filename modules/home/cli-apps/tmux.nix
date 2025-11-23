{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.tmux;
in
{
  options.plusultra.cli-apps.tmux = with types; {
    enable = mkBoolOpt false "Whether or not to enable tmux.";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      mouse = true;
      keyMode = "vi";
      prefix = "C-a";
      baseIndex = 1;
      shell = "${pkgs.fish}/bin/fish";

      plugins = with pkgs.tmuxPlugins; [
        sensible
        vim-tmux-navigator
        yank
        {
          plugin = tmux-sessionx;
          extraConfig = ''
            set -g @sessionx-bind 'o'
            set -g @sessionx-zoxide-mode 'on'
          '';
        }
        {
          plugin = tokyo-night-tmux;
          extraConfig = ''
            set -g @tokyo-night-tmux_show_datetime 0
            set -g @tokyo-night-tmux_show_path 1
            set -g @tokyo-night-tmux_path_format relative
            set -g @tokyo-night-tmux_window_id_style dsquare
            set -g @tokyo-night-tmux_show_git 0
          '';
        }
      ];

      extraConfig = ''
        set-option -sa terminal-overrides ",xterm*:Tc"

        # Send C-a through to shell when pressed twice
        bind a send-prefix

        # Vim style pane selection
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Use Alt-arrow keys without prefix key to switch panes
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D

        # Shift arrow to switch windows
        bind -n S-Left  previous-window
        bind -n S-Right next-window

        # Alt vim keys to switch windows (lowercase for easier access)
        bind -n M-h previous-window
        bind -n M-l next-window

        # keybindings
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # Custom split bindings
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"

        # Reload config
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"

        set-option -g default-command "${pkgs.fish}/bin/fish"
      '';
    };
  };
}
