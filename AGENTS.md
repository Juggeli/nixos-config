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
# Build a NixOS host's system closure
nix build .#nixosConfigurations.haruka.config.system.build.toplevel
nix build .#nixosConfigurations.noel.config.system.build.toplevel

# Build a nix-darwin host's system closure
nix build .#darwinConfigurations.Jukkas-MBP.system
nix build .#darwinConfigurations.kuro.system
```

### Rebuild / Deploy
```bash
# Rebuild the current machine (run on the host itself)
sudo nixos-rebuild switch --flake .#<hostname>   # haruka | noel
darwin-rebuild switch --flake .#<hostname>       # Jukkas-MBP | kuro
```
There is no deploy-rs setup; deployment is a plain `nixos-rebuild` / `darwin-rebuild` on the target.

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
hold non-module files).

### Module kinds
Each file under `modules/` is one of:
- **flake-parts modules** — set top-level outputs or `perSystem` (e.g.
  `modules/systems.nix`, `modules/lib.nix`, `modules/overlays.nix`,
  `modules/formatter.nix`).
- **NixOS module definitions** — `{ flake.nixosModules.<name> = { ... }; }`. These
  are only *registered* as outputs; they do nothing until a host composes them.
- **nix-darwin module definitions** — `{ flake.darwinModules.<name> = { ... }; }`,
  living under `modules/darwin/`.
- **Cross-platform system modules** — files under `modules/common/` that export
  the same definition as both a nixosModule and a darwinModule (e.g.
  `nix-settings`, `home-manager`, `agenix-shared`).
- **Home modules** — `{ flake.homeModules.<name> = { ... }; }`, living under
  `modules/home/`. These configure `home-manager.users.juggeli.*` and are
  *cross-platform*: both NixOS and nix-darwin hosts compose them. The
  `flake.homeModules` / `flake.darwinModules` / `flake.darwinConfigurations`
  output options are not provided by flake-parts core, so they are declared in
  `modules/flake-outputs.nix`.
- **Profile (aggregate) modules** — modules that only `imports` other modules to
  form a shared baseline: `nixosModules.base` (`modules/nixos/base.nix`),
  `darwinModules.base` (`modules/darwin/base.nix`, composes every shared darwin
  module), `homeModules.base` (CLI tools used on all hosts) and
  `homeModules.desktop` (base + terminal/GUI apps shared by noel and the Macs).
  Host files list a profile plus their genuinely host-specific extras.
- **Host definitions** — `modules/hosts/<host>/default.nix` sets
  `flake.nixosConfigurations.<host>` (via `self.lib.mkNixos`) or
  `flake.darwinConfigurations.<host>` (via `self.lib.mkDarwin`), selecting modules
  with `with self.nixosModules; [ ... ]` / `with self.darwinModules; [ ... ]` and
  `with self.homeModules; [ ... ]`.

`mkNixos` and `mkDarwin` live in `modules/lib.nix` and default `system` to
`x86_64-linux` / `aarch64-darwin`. `mkNixos` wires in home-manager, agenix,
disko, impermanence, catppuccin, and neovim; `mkDarwin` wires in home-manager
and agenix.

### Directory Structure
- `modules/nixos/` - reusable NixOS modules, each exporting `flake.nixosModules.<name>`
- `modules/darwin/` - reusable nix-darwin modules, each exporting `flake.darwinModules.<name>`
- `modules/common/` - cross-platform system modules exported to both nixosModules and darwinModules
- `modules/home/` - cross-platform home modules, each exporting `flake.homeModules.<name>`
- `modules/hosts/<host>/` - per-host config; `default.nix` assembles the host
- `modules/lib.nix` - `mkNixos` / `mkDarwin` builders + shared nixpkgs overlay list (`flake.lib.overlays`)
- `modules/systems.nix` - supported systems + `perSystem` pkgs
- `modules/overlays.nix` - `overlays.default`, wiring `packages/` into nixpkgs
- `modules/flake-outputs.nix` - declares the `homeModules` / `darwinModules` / `darwinConfigurations` output options
- `modules/formatter.nix` - treefmt formatter (`nix fmt`)
- `packages/` - custom package derivations exposed via the overlay
- `tools/` - standalone scripts / sub-flakes (hdd-scraper, process-anime, sorter)

### Hosts
Two NixOS hosts, both `x86_64-linux`: `haruka` (media/server) and `noel`. Two
nix-darwin hosts, both `aarch64-darwin`: `Jukkas-MBP` (work laptop) and `kuro`.

### Home Manager
Home Manager is integrated into each system (not a separate output). The
`home-manager` nixos/darwin module sets up the `juggeli` user, and per-feature
modules under `modules/home/` (e.g. `flake.homeModules.bat`,
`flake.homeModules.neovim`) add to `home-manager.users.juggeli.*`. These modules
are cross-platform — guard Linux-only bits with `lib.optionals/optionalString
pkgs.stdenv.isLinux` (in option *values*, never in a module's top-level attrset
keys, which would cause infinite recursion). Impermanence (`environment.persistence`)
is a NixOS-only concern and must NOT live in cross-platform home modules; declare
those paths in `modules/nixos/home-impermanence.nix` instead.

### Special Features
- **Secrets**: agenix. Shared secrets in `modules/common/agenix-shared/_secrets/`,
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
