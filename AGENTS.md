# AGENTS.md

## Workflow

- Before the first host-dependent task in a session, run `hostname` to identify
  the current machine.
- Format with `nix fmt`.
- Run `nix flake check` on a NixOS host.

## Conventions

- Comments may explain non-obvious current behavior; never use them to record
  change history such as "was X, now Y."
- Guard platform-specific Home Manager option values with
  `lib.optionals`/`lib.optionalString`; do not conditionally construct a module's
  top-level attribute keys, which can cause infinite recursion.
- Keep impermanence paths in NixOS modules, not cross-platform Home Manager
  modules.
- Use Conventional Commits and keep unrelated changes in separate commits.
