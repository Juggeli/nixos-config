# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NixOS/Darwin dotfiles repository using Snowfall Lib for structured organization. The namespace is "plusultra" and configurations support NixOS, macOS (Darwin), and multiple architectures.

## Key Commands

### Building Configurations
```bash
# Build system configurations
nix build .#nixosConfigurations.haruka
nix build .#nixosConfigurations.noel
nix build .#darwinConfigurations.Jukkas-MBP

# Build home configurations  
nix build .#homeConfigurations.juggeli@haruka
nix build .#homeConfigurations.juggeli@noel
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

# Enter development shell
nix develop
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
- Uses `enabled`/`disabled` helpers for clean module toggling
- Options are namespaced under `plusultra.*`
- `suites/` provide pre-configured module bundles (common, desktop, development, media)
- Individual modules can be granularly enabled

### Special Features
- **Secrets**: Uses agenix for encrypted secrets in `systems/*/secrets/`
- **Impermanence**: Configured for ephemeral root filesystems
- **Deploy-rs**: Automated remote deployment with verification
- **Container Services**: Extensive media server stack via Podman containers

## Manual Setup Notes
- macOS: Start Aerospace window manager on first launch

## Development Tips
- Use 'nix store prefetch-file' to check hashes instead of 'nix-prefetch-url'

## Configuration Tips
- Use plusultra.home.configFile.<file> option to make config files in home dir

## Coding Guidelines
- Dont leave code comments, unless the code is not obvious