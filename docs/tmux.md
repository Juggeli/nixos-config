# tmux Configuration Guide

This is a comprehensive guide for using tmux with our custom configuration.

## Quick Start

### Installation
tmux is installed via our NixOS configuration. Enable it in your system by adding:
```nix
plusultra.cli-apps.tmux.enabled = true;
```

### Basic Concepts
- **Session**: A collection of windows, persists when you disconnect
- **Window**: Like a tab, contains one or more panes
- **Pane**: A single terminal within a window

## Key Bindings

### Prefix Key
**Prefix**: `Ctrl+Space` (custom, default is `Ctrl+b`)

All tmux commands start with the prefix key unless noted as "no prefix".

### Session Management
| Command | Description |
|---------|-------------|
| `tmux new -s <name>` | Create new named session |
| `tmux ls` | List all sessions |
| `tmux attach -t <name>` | Attach to session |
| `tmux kill-session -t <name>` | Kill session |
| `prefix + d` | Detach from current session |
| `prefix + s` | Show session list |

### Window Management
| Command | Description |
|---------|-------------|
| `prefix + c` | Create new window |
| `prefix + &` | Close current window (with confirmation) |
| `prefix + ,` | Rename current window |
| `prefix + w` | List windows |
| `prefix + n` | Next window |
| `prefix + p` | Previous window |
| `prefix + 0-9` | Switch to window by number |
| `Shift + Left/Right` | Switch windows (no prefix) |
| `Alt + H/L` | Switch windows with vim keys (no prefix) |

### Pane Management
| Command | Description |
|---------|-------------|
| `prefix + "` | Split horizontally |
| `prefix + %` | Split vertically |
| `prefix + x` | Close current pane |
| `prefix + z` | Toggle pane zoom |
| `prefix + q` | Show pane numbers |
| `prefix + o` | Cycle through panes |

### Pane Navigation
| Command | Description |
|---------|-------------|
| `prefix + h/j/k/l` | Navigate panes (vim-style) |
| `Alt + Arrow Keys` | Navigate panes (no prefix) |
| `Ctrl + h/j/k/l` | Seamless vim-tmux navigation |

### Copy Mode (Vi-style)
| Command | Description |
|---------|-------------|
| `prefix + [` | Enter copy mode |
| `v` | Begin selection |
| `Ctrl + v` | Rectangle selection |
| `y` | Copy selection and exit |
| `prefix + ]` | Paste |
| `q` or `Escape` | Exit copy mode |

### Resizing Panes
| Command | Description |
|---------|-------------|
| `prefix + Ctrl + Arrow` | Resize pane |
| `prefix + Alt + Arrow` | Resize pane in larger steps |

## Features

### Mouse Support
Mouse support is enabled by default:
- Click to select panes
- Scroll to navigate history
- Drag pane borders to resize
- Right-click for context menu

### Vi Mode
The configuration uses vi-style key bindings:
- Copy mode uses vim navigation (`h`, `j`, `k`, `l`)
- Visual selection with `v`
- Copy with `y`

### Plugins
Our configuration includes these plugins managed via Nix:
- **tmux-sensible**: Sensible defaults
- **vim-tmux-navigator**: Seamless vim-tmux navigation
- **tmux-yank**: Enhanced copy functionality
- **tokyo-night-tmux**: Beautiful theme

### Smart Defaults
- Windows and panes start at 1 (not 0)
- New panes/windows open in current directory
- Automatic window renumbering
- Enhanced terminal color support
- Increased history limit

## Common Workflows

### Development Workflow
1. Create a session for your project:
   ```bash
   tmux new -s myproject
   ```

2. Split into panes:
   - `prefix + "` for horizontal split (editor on top, terminal below)
   - `prefix + %` for vertical split (editor left, terminal right)

3. Navigate between panes with `Ctrl + h/j/k/l`

### Multi-window Setup
1. Create windows for different tasks:
   - `prefix + c` for new window
   - `prefix + ,` to rename (e.g., "editor", "server", "logs")

2. Switch between windows:
   - `Shift + Left/Right` to navigate
   - `prefix + 0-9` for direct access

### Remote Work
1. Start a session on remote server:
   ```bash
   ssh user@server
   tmux new -s work
   ```

2. Detach when done: `prefix + d`

3. Reconnect later:
   ```bash
   ssh user@server
   tmux attach -t work
   ```

## Configuration Details

### Custom Settings
- **Prefix**: Changed from `Ctrl+b` to `Ctrl+Space` for easier access
- **Terminal**: Enhanced 256-color support with RGB colors
- **History**: 100,000 lines of scrollback
- **Base Index**: Windows and panes start at 1
- **Mouse**: Enabled for modern usage

### Theme Configuration
Tokyo Night theme is configured with:
- No datetime display
- Relative path display
- Square window indicators
- Git integration disabled

## Troubleshooting

### Colors Not Working
Ensure your terminal supports 256 colors:
```bash
echo $TERM
# Should show: screen-256color or tmux-256color
```

### Vim Navigation Issues
If `Ctrl + h/j/k/l` doesn't work between vim and tmux:
1. Ensure vim-tmux-navigator plugin is installed in vim
2. Check that the plugin is loaded in tmux

### Copy/Paste Issues
- Use `y` to copy in copy mode
- Use `prefix + ]` to paste
- For system clipboard, ensure tmux-yank plugin is working

## Advanced Usage

### Custom Key Bindings
Add custom bindings in the tmux configuration:
```bash
bind-key r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
```

### Session Scripting
Create startup scripts for complex layouts:
```bash
#!/bin/bash
tmux new-session -d -s development
tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux send-keys 'nvim' Enter
tmux attach-session -t development
```

### Nested Sessions
When using tmux inside tmux (e.g., local and remote):
- Use `prefix + prefix + command` for inner session
- Or temporarily disable outer session with `prefix + F12`

## Resources

- [tmux Manual](https://man.openbsd.org/tmux.1)
- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Our tmux Configuration](../modules/home/cli-apps/tmux.nix)