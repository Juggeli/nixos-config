# AGENTS.md — pi-agents repository conventions

## Commits

Mixed **gitmoji + Conventional Commits** style. Both coexist, either is fine.
Examples from the log:

```
✨ feat(delegate): progressive transcript with resolved tool markers
🐛 fix: migrate delegate to ModelRuntime for pi >= 0.80.8
♻️ refactor(runner): structured tool call entries, prevent overwrites
📝 docs: explain opt-in design — declare only what the agent needs
🎨 Bannière ASCII centrée avec tagline
🔥 Remove unused outputFormat field
```

Common emojis:

| Emoji | Usage |
|-------|-------|
| ✨ | New feature |
| 🐛 | Bug fix |
| 🔖 | Version bump |
| ♻️ | Refactoring (no functional change) |
| 📝 | Documentation (README, comments) |
| 🎨 | Format, structure, style |
| 🔥 | Code removal |
| 🌐 | Internationalization |

One commit = one coherent change. Subject in English or French, imperative,
concise. Optional body explains the why.

## Versioning

The project follows [SemVer](https://semver.org). Current version lives in
`package.json` and at the top of `CHANGELOG.md`.

### Bump criteria

| Bump | When |
|------|------|
| **PATCH** (`1.2.3 → 1.2.4`) | Bug fix with no API change. Fixing broken behavior, a critical typo. |
| **MINOR** (`1.2.0 → 1.3.0`) | Backward-compatible new feature. New agent, new frontmatter option, new tool. |
| **MAJOR** (`1.0.0 → 2.0.0`) | Breaking change. Removing a public API field, changing default behavior, major peerDependency bump. |

When unsure, take the lowest bump that covers the most impactful change.

### Release process

1. Update the version in `package.json`.
2. Add the matching entry at the top of `CHANGELOG.md` ([Keep a
   Changelog](https://keepachangelog.com/en/1.1.0/) format).
3. Commit with `🔖`: `🔖 X.Y.Z` (or `Bump version to X.Y.Z`).
4. Optional: tag with `git tag vX.Y.Z`.

## Changelog

[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. Sections:

- `### Added` — new features
- `### Changed` — changes to existing behavior
- `### Fixed` — bug fixes
- `### Removed` — removed features

Each entry is a sentence in English or French, infinitive or past tense.
Sub-lists use `-`.

Don't group changes of different natures under the same entry.
One line = one distinct change.

## Pre-commit checks

A `.git/hooks/pre-commit` hook runs automatically before each commit:

- `npm run lint` — Prettier format check
- `npm run typecheck` — `tsc --noEmit`
- `npm test` — Node test suite

All three must pass. Fix formatting with `npm run format`.
