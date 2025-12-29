# AGENTS.md

This file provides guidance to AI agents working with code in this repository.

## Project Overview

This is a NixOS/Darwin dotfiles repository using Snowfall Lib for structured organization. The namespace is "plusultra" and configurations support NixOS, macOS (Darwin), and multiple architectures.

## Key Commands

### Building Configurations
```bash
# Build system configurations (use config.system.build.toplevel)
nix build .#nixosConfigurations.haruka.config.system.build.toplevel
nix build .#nixosConfigurations.noel.config.system.build.toplevel

# Note: Home configurations currently have missing home.stateVersion and cannot be built
# Available home configs: juggeli@Jukkas-MBP, juggeli@haruka, juggeli@kuki, juggeli@noel
```

### Deployment
```bash
# Deploy to remote hosts using deploy-rs
nix run .#deploy

# Local system rebuild
nixos-rebuild switch --flake .#<hostname>
darwin-rebuild switch --flake .#<hostname>
```

### Development
```bash
# Validate flake and check all configurations
nix flake check

# Show available outputs
nix flake show

# Note: No default development shell is configured
# Check available shells with: nix eval --json .#devShells.x86_64-linux --apply builtins.attrNames
```

## Architecture

### Directory Structure
- `systems/` - Host-specific configurations organized by architecture
- `homes/` - User-specific Home Manager configurations per architecture/host
- `modules/` - Modular configuration split by platform:
  - `modules/nixos/` - NixOS system modules
  - `modules/home/` - Home Manager modules
  - `modules/darwin/` - macOS/Darwin modules
- `lib/` - Custom library functions and deploy helpers
- `overlays/` - Package overlays

### Module System
- Uses `enabled`/`disabled` helpers for clean module toggling, note that `enabled`
equals to { enabled = true; }, do not try to set just boolean values to enabled
- Options are namespaced under `plusultra.*`
- `suites/` provide pre-configured module bundles (common, desktop, development, media)
- Individual modules can be granularly enabled

### Special Features
- **Secrets**: Uses agenix for encrypted secrets in `systems/*/secrets/`
- **Impermanence**: Configured for ephemeral root filesystems
- **Deploy-rs**: Automated remote deployment with verification
- **Container Services**: Extensive media server stack via Podman containers
- **Homepage Dashboard**: Dynamic service detection with API widget support for enhanced monitoring

## Manual Setup Notes
- macOS: Start Aerospace window manager on first launch

## Development Tips
- Use 'nix store prefetch-file' to check hashes instead of 'nix-prefetch-url'

## Configuration Tips
- Use plusultra.home.configFile.<file> option to make config files in home dir
- Homepage API widgets: Set apiKey in container configs to enable enhanced monitoring (e.g., bazarr.homepage.widget.apiKey)

## Coding Guidelines
- Don't leave code comments, unless the code is not obvious

## Development Reminders
- Remember to git add any new files, no need to add changed files
- Don't leave code comments, unless the code is not obvious
- Don't add unrelated things to same commit, make separate commits for those
