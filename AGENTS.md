# AGENTS.md

This file provides guidance to AI agents working with code in this repository.

## Project Overview

This is a NixOS dotfiles repository built with flake-parts and `vic/import-tree`
(the "dendritic" pattern). Every `.nix` file under `modules/` is a flake-parts
module that is auto-imported and merged. There is no Snowfall, no `plusultra`
namespace, and no `enabled`/`disabled` helpers.

## Key Commands

### Building Configurations
```bash
# Build a host's system closure
nix build .#nixosConfigurations.haruka.config.system.build.toplevel
nix build .#nixosConfigurations.noel.config.system.build.toplevel
```

### Rebuild / Deploy
```bash
# Rebuild the current machine (run on the host itself)
sudo nixos-rebuild switch --flake .#<hostname>   # haruka | noel
```
There is no deploy-rs setup; deployment is a plain `nixos-rebuild` on the target.

### Development
```bash
nix fmt           # format the tree with treefmt (nixfmt) — see modules/formatter.nix
nix flake check   # validate all configs; includes the treefmt formatting check
nix flake show    # list flake outputs
```
There is no devShell defined.

## Architecture

### Flake wiring
`flake.nix` is a thin entrypoint:
```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
```
`import-tree` recursively imports every `.nix` file under `modules/`. Any path
whose name starts with `_` is ignored (used for `_secrets/` and `_assets/` that
hold non-module files). `legacy/` is the pre-migration Snowfall config and is
**not** part of the flake.

### Module kinds
Each file under `modules/` is one of:
- **flake-parts modules** — set top-level outputs or `perSystem` (e.g.
  `modules/systems.nix`, `modules/lib.nix`, `modules/overlays.nix`,
  `modules/formatter.nix`).
- **NixOS module definitions** — `{ flake.nixosModules.<name> = { ... }; }`. These
  are only *registered* as outputs; they do nothing until a host composes them.
- **Host definitions** — `modules/hosts/<host>/default.nix` sets
  `flake.nixosConfigurations.<host>` via `self.lib.mkNixos`, selecting modules
  with `with self.nixosModules; [ ... ]`.

`mkNixos` (and an unused `mkDarwin`) live in `modules/lib.nix`; they wire in
home-manager, agenix, disko, impermanence, catppuccin, and neovim.

### Directory Structure
- `modules/nixos/` - reusable NixOS modules, each exporting `flake.nixosModules.<name>`
- `modules/hosts/<host>/` - per-host config; `default.nix` assembles the host
- `modules/lib.nix` - `mkNixos` / `mkDarwin` builders
- `modules/systems.nix` - supported systems + `perSystem` pkgs
- `modules/overlays.nix` - `overlays.default`, wiring `packages/` into nixpkgs
- `modules/formatter.nix` - treefmt formatter (`nix fmt`)
- `packages/` - custom package derivations exposed via the overlay
- `tools/` - standalone scripts / sub-flakes (hdd-scraper, process-anime, sorter)
- `legacy/` - old Snowfall layout, not imported by the active flake

### Hosts
Two NixOS hosts, both `x86_64-linux`: `haruka` (media/server) and `noel`. The
`mkDarwin` helper and `aarch64-darwin` system exist, but no darwin host is
currently defined.

### Home Manager
Home Manager is integrated into each NixOS system (not a separate output). The
`home-manager` nixos module sets up the `juggeli` user, and per-feature
`home-*` modules (e.g. `home-bat`, `home-neovim`) add to
`home-manager.users.juggeli.*`. To add config to the home dir, use standard
home-manager options (`home.file`, `xdg.configFile`, `programs.*`).

### Special Features
- **Secrets**: agenix. Shared secrets in `modules/nixos/agenix-shared/_secrets/`,
  per-host secrets in `modules/hosts/<host>/_secrets/`.
- **Impermanence**: ephemeral root; modules declare persisted paths via
  `environment.persistence."/persist-home"`.
- **Container Services**: media stack via `virtualisation.oci-containers`
  (podman backend), defined in `modules/hosts/haruka/containers.nix` and
  `media-stack.nix`.
- **Homepage Dashboard**: `services.homepage-dashboard` in
  `modules/hosts/haruka/homepage.nix`.

## Development Tips
- Use `nix store prefetch-file` to check hashes instead of `nix-prefetch-url`.

## Coding Guidelines
- Don't leave code comments, unless the code is not obvious.

## Development Reminders
- Remember to git add any new files, no need to add changed files.
- Don't leave code comments, unless the code is not obvious.
- Don't add unrelated things to same commit, make separate commits for those.
- Before working on configs, checking logs, or debugging: always check which
  machine you are on first (`hostname`). This repo manages multiple hosts and the
  current machine determines which config applies and where to look for issues.
