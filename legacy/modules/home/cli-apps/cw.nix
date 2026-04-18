{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.cw;

  cwScript = pkgs.writeShellScriptBin "cw" ''
        set -euo pipefail

        WORKTREE_DIR=".worktrees"

        get_main_worktree() {
          git worktree list --porcelain | head -1 | sed 's/^worktree //'
        }

        ensure_gitignore() {
          local root
          root=$(get_main_worktree)
          local exclude_file="$root/.git/info/exclude"
          if ! grep -qxF "$WORKTREE_DIR" "$exclude_file" 2>/dev/null; then
            echo "$WORKTREE_DIR" >> "$exclude_file"
            echo "Added $WORKTREE_DIR to .git/info/exclude"
          fi
        }

        get_window_name() {
          local branch="$1"
          local name
          name=$(echo "$branch" | tr '/' '-')
          local max_len=10
          if [ ''${#name} -le $max_len ]; then
            echo "$name"
          else
            local prefix_len=5
            local suffix_len=4
            local prefix suffix
            prefix=$(echo "$name" | cut -c1-$prefix_len)
            suffix=$(echo "$name" | rev | cut -c1-$suffix_len | rev)
            echo "''${prefix}~''${suffix}"
          fi
        }

        require_tmux() {
          if [ -z "''${TMUX:-}" ]; then
            echo "Error: Must be inside tmux to use cw"
            exit 1
          fi
        }

        window_exists() {
          local name="$1"
          ${pkgs.tmux}/bin/tmux list-windows -F '#W' | grep -qx "$name"
        }

        list_worktrees() {
          local root
          root=$(get_main_worktree)
          if [ -d "$root/$WORKTREE_DIR" ]; then
            for dir in "$root/$WORKTREE_DIR"/*/; do
              [ -d "$dir" ] || continue
              basename "$dir"
            done
          fi
        }

        get_branches() {
          git branch -a --format='%(refname:short)' | while read -r branch; do
            if [[ "$branch" == origin/* ]]; then
              echo "$branch"
            else
              echo "$branch (local)"
            fi
          done | sort -u
        }

        strip_origin() {
          local branch="$1"
          echo "$branch" | sed 's|^origin/||'
        }

        cmd_new() {
          require_tmux
          local branch="$1"
          local root
          root=$(get_main_worktree)

          if [ -z "$branch" ]; then
            branch=$(get_branches | ${pkgs.fzf}/bin/fzf --prompt="Select branch: " --height=40%)
            [ -z "$branch" ] && exit 0
            branch=$(echo "$branch" | sed 's/ (local)$//')
          fi

          local is_remote=false
          if [[ "$branch" == origin/* ]]; then
            is_remote=true
            branch=$(strip_origin "$branch")
          fi

          local clean_branch
          clean_branch=$(echo "$branch" | tr '/' '-')
          local worktree_path="$root/$WORKTREE_DIR/$clean_branch"

          if [ -d "$worktree_path" ]; then
            echo "Worktree already exists: $worktree_path"
            echo "Use 'cw open' to open it"
            exit 1
          fi

          ensure_gitignore
          mkdir -p "$root/$WORKTREE_DIR"

          if $is_remote; then
            git worktree add "$worktree_path" -b "$branch" "origin/$branch"
          elif git show-ref --verify --quiet "refs/heads/$branch"; then
            git worktree add "$worktree_path" "$branch"
          else
            git worktree add "$worktree_path" -b "$branch"
          fi

          local window_name
          window_name=$(get_window_name "$clean_branch")

          if window_exists "$window_name"; then
            ${pkgs.tmux}/bin/tmux kill-window -t "$window_name"
          fi

          ${pkgs.tmux}/bin/tmux new-window -n "$window_name" -c "$worktree_path"
        }

        cmd_open() {
          require_tmux
          local worktrees
          worktrees=$(list_worktrees)

          if [ -z "$worktrees" ]; then
            echo "No worktrees found"
            exit 1
          fi

          local root
          root=$(get_main_worktree)

          local selection
          selection=$(echo "$worktrees" | while read -r wt; do
            local window_name
            window_name=$(get_window_name "$wt")
            if window_exists "$window_name"; then
              echo "$wt (open)"
            else
              echo "$wt"
            fi
          done | ${pkgs.fzf}/bin/fzf --prompt="Select worktree: " --height=40%)

          [ -z "$selection" ] && exit 0

          local branch
          branch=$(echo "$selection" | sed 's/ (open)$//')
          local worktree_path="$root/$WORKTREE_DIR/$branch"
          local window_name
          window_name=$(get_window_name "$branch")

          if window_exists "$window_name"; then
            ${pkgs.tmux}/bin/tmux select-window -t "$window_name"
          else
            ${pkgs.tmux}/bin/tmux new-window -n "$window_name" -c "$worktree_path"
          fi
        }

        cmd_rm() {
          local root
          root=$(get_main_worktree)
          local current_dir
          current_dir=$(pwd)

          local branch=""
          if [[ "$current_dir" == "$root/$WORKTREE_DIR/"* ]]; then
            branch=$(basename "$current_dir")
          else
            local worktrees
            worktrees=$(list_worktrees)

            if [ -z "$worktrees" ]; then
              echo "No worktrees found"
              exit 1
            fi

            branch=$(echo "$worktrees" | ${pkgs.fzf}/bin/fzf --prompt="Select worktree to remove: " --height=40%)
            [ -z "$branch" ] && exit 0
          fi
          local worktree_path="$root/$WORKTREE_DIR/$branch"
          local window_name
          window_name=$(get_window_name "$branch")

          read -rp "Delete worktree '$branch'? [y/N] " confirm
          [[ "$confirm" != [yY] ]] && exit 0

          cd "$root"

          if [ -n "''${TMUX:-}" ] && window_exists "$window_name"; then
            local current_window
            current_window=$(${pkgs.tmux}/bin/tmux display-message -p '#W')
            if [ "$current_window" = "$window_name" ]; then
              ${pkgs.tmux}/bin/tmux new-window -c "$root"
            fi
            ${pkgs.tmux}/bin/tmux kill-window -t "$window_name"
            echo "Killed window: $window_name"
          fi

          git worktree remove "$worktree_path" --force
          echo "Removed worktree: $worktree_path"

          read -rp "Also delete branch '$branch'? [y/N] " delete_branch
          if [[ "$delete_branch" == [yY] ]]; then
            git branch -D "$branch" 2>/dev/null || echo "Branch not found or already deleted"
          fi
        }

        cmd_list() {
          local worktrees
          worktrees=$(list_worktrees)

          if [ -z "$worktrees" ]; then
            echo "No worktrees found"
            exit 0
          fi

          local in_tmux=false
          [ -n "''${TMUX:-}" ] && in_tmux=true

          printf "%-30s %-40s %s\n" "BRANCH" "WORKTREE" "WINDOW"
          echo "$worktrees" | while read -r wt; do
            local window_name
            window_name=$(get_window_name "$wt")
            local window_status
            if $in_tmux && window_exists "$window_name"; then
              window_status="$window_name"
            else
              window_status="-"
            fi
            printf "%-30s %-40s %s\n" "$wt" "$WORKTREE_DIR/$wt" "$window_status"
          done
        }

        cmd_studio() {
          open -a "Android Studio" .
        }

        cmd_help() {
          cat <<EOF
    Usage: cw <command> [args]

    Commands:
      new [branch]    Create worktree + tmux window
                      Without branch: fzf picker for local/remote branches
                      With branch: create new branch from HEAD
      open            Open existing worktree in new window (fzf picker)
      rm              Remove worktree + kill window (fzf picker)
      list            Show all worktrees and window status
      studio          Open Android Studio in current directory
      help            Show this help

    Examples:
      cw new              # Pick from existing branches
      cw new my-feature   # Create new branch 'my-feature'
      cw open             # Pick worktree to open
      cw rm               # Pick worktree to remove

    Note: Must be run inside tmux (except for 'list', 'studio' and 'help')
    EOF
        }

        case "''${1:-help}" in
          new)
            cmd_new "''${2:-}"
            ;;
          open)
            cmd_open
            ;;
          rm)
            cmd_rm
            ;;
          list)
            cmd_list
            ;;
          studio)
            cmd_studio
            ;;
          help|--help|-h)
            cmd_help
            ;;
          *)
            echo "Unknown command: $1"
            cmd_help
            exit 1
            ;;
        esac
  '';
in
{
  options.plusultra.cli-apps.cw = with types; {
    enable = mkBoolOpt false "Whether or not to enable cw (claude-worktree).";
  };

  config = mkIf cfg.enable {
    home.packages = [ cwScript ];
  };
}
