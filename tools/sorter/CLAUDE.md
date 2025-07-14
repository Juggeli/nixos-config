# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sorter is an interactive TUI (Terminal User Interface) media file organizer built in Go using the Bubble Tea framework. It replaces a previous Fish shell script and provides a modern interface for sorting video files into categories.

## Key Commands

### Building and Running
```bash
# With direnv (recommended - automatically loads Go environment)
go build -o sorter

# Without direnv (manual nix-shell)
nix-shell -p go --run "go build -o sorter"

# Run the application
./sorter

# Run in dry-run mode (preview operations without executing)
./sorter --dry-run
./sorter -n

# Test configuration loading
./sorter --test-config

# Show help
./sorter --help
```

### Development
```bash
# Direnv automatically loads development environment on directory entry
# If direnv is not available, use:
nix develop  # or nix-shell -p go

# Build and test
go build -o sorter
go mod tidy  # Update dependencies
go mod verify  # Verify dependencies
go run .  # Run without building binary
```

## Architecture

### Core Components
- **main.go**: Entry point, command line parsing, and configuration loading
- **config.go**: Configuration management (YAML-based config in `~/.config/sorter/config.yaml`)
- **tui.go**: Bubble Tea TUI implementation with interactive file review
- **scanner.go**: File system scanning for video files
- **processor.go**: File operations (move, delete, cleanup)
- **logger.go**: Operation logging to `~/.config/sorter/operations.log`
- **default-config.yaml**: Template configuration copied on first run

### Key Dependencies
- **Bubble Tea**: TUI framework for interactive terminal applications
- **Lipgloss**: Styling and layout for terminal UI
- **go-homedir**: Cross-platform home directory detection
- **yaml.v3**: YAML configuration parsing

### Configuration System
- YAML-based configuration in `~/.config/sorter/config.yaml`
- Default configuration created from `default-config.yaml` on first run
- Configurable categories with custom paths and hotkeys
- Junk file detection patterns with wildcard support
- Video file extensions and media player integration

### Application Flow
1. **Scanning Phase**: Recursively scans base directory for video files
2. **Review Phase**: Interactive TUI for file-by-file review with media preview
3. **Confirmation Phase**: Batch review of all pending operations
4. **Processing Phase**: Executes file operations and cleanup
5. **Completion**: Results summary and empty directory cleanup

### TUI Features
- File navigation with keyboard controls
- Media player integration (mpv) for file preview
- Dynamic junk pattern detection and addition
- Batch operation confirmation
- Progress tracking and status indicators
- Configurable category hotkeys

## Development Notes

### No Test Suite
This project currently has no test files. Any testing is done manually through the `--test-config` and `--dry-run` flags.

### File Operations
- All file operations are logged to `~/.config/sorter/operations.log`
- Dry-run mode provides detailed operation previews without modifications
- Automatic cleanup of empty directories and junk files
- Pattern-based junk video detection with dynamic pattern addition

### Development Environment
- **Flake**: Provides reproducible Go development environment with LSP and tools
- **Direnv**: Automatically loads development environment when entering directory
- **Tools included**: go, gopls, gotools, go-outline, gocode-gomod, gopkgs, godef, golint, delve

### Integration
- Designed to work within NixOS/Darwin dotfiles ecosystem
- Uses mpv for media preview (hardcoded in main.go:64)
- Cross-platform compatibility (Linux and macOS)