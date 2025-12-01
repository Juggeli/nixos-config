---
description: Create well-formatted commits with conventional commit messages and emoji
---

Create a git commit following this process:

## Pre-commit Checks

$ARGUMENTS

Unless the argument contains `--no-verify`, run these checks first:
1. Run `treefmt` to format all files
2. Run `nix flake check` to validate the flake
3. Run `nixos-rebuild build --flake .#` to test the configuration builds

If any check fails, ask whether to proceed or fix the issues first.

## Staging Files

1. Check `git status` to see which files are staged
2. If no files are staged, automatically stage all modified and new files with `git add`
3. Run `git diff --staged` to see what will be committed

## Analyze Changes

Review the diff and determine:
1. Are there multiple distinct logical changes that should be separate commits?
2. If yes, suggest splitting into multiple commits and help stage/commit them separately

## Commit Message Format

Use emoji conventional commit format: `<emoji> <type>: <description>`

Emoji reference by type:
- ✨ `feat`: New feature
- 🐛 `fix`: Bug fix
- 📝 `docs`: Documentation
- 💄 `style`: Formatting/style
- ♻️ `refactor`: Code refactoring
- ⚡️ `perf`: Performance improvements
- ✅ `test`: Tests
- 🔧 `chore`: Tooling, configuration
- 🚀 `ci`: CI/CD improvements
- 🗑️ `revert`: Reverting changes
- 🧪 `test`: Add a failing test
- 🚨 `fix`: Fix compiler/linter warnings
- 🔒️ `fix`: Fix security issues
- 👥 `chore`: Add or update contributors
- 🚚 `refactor`: Move or rename resources
- 🏗️ `refactor`: Make architectural changes
- 🔀 `chore`: Merge branches
- 📦️ `chore`: Add or update compiled files or packages
- ➕ `chore`: Add a dependency
- ➖ `chore`: Remove a dependency
- 🌱 `chore`: Add or update seed files
- 🧑‍💻 `chore`: Improve developer experience
- 🧵 `feat`: Add or update code related to multithreading or concurrency
- 🔍️ `feat`: Improve SEO
- 🏷️ `feat`: Add or update types
- 💬 `feat`: Add or update text and literals
- 🌐 `feat`: Internationalization and localization
- 👔 `feat`: Add or update business logic
- 📱 `feat`: Work on responsive design
- 🚸 `feat`: Improve user experience / usability
- 🩹 `fix`: Simple fix for a non-critical issue
- 🥅 `fix`: Catch errors
- 👽️ `fix`: Update code due to external API changes
- 🔥 `fix`: Remove code or files
- 🎨 `style`: Improve structure/format of the code
- 🚑️ `fix`: Critical hotfix
- 🎉 `chore`: Begin a project
- 🔖 `chore`: Release/Version tags
- 🚧 `wip`: Work in progress
- 💚 `fix`: Fix CI build
- 📌 `chore`: Pin dependencies to specific versions
- 👷 `ci`: Add or update CI build system
- 📈 `feat`: Add or update analytics or tracking code
- ✏️ `fix`: Fix typos
- ⏪️ `revert`: Revert changes
- 📄 `chore`: Add or update license
- 💥 `feat`: Introduce breaking changes
- 🍱 `assets`: Add or update assets
- ♿️ `feat`: Improve accessibility
- 💡 `docs`: Add or update comments in source code
- 🗃️ `db`: Perform database related changes
- 🔊 `feat`: Add or update logs
- 🔇 `fix`: Remove logs
- 🤡 `test`: Mock things
- 🥚 `feat`: Add or update an easter egg
- 🙈 `chore`: Add or update .gitignore file
- 📸 `test`: Add or update snapshots
- ⚗️ `experiment`: Perform experiments
- 🚩 `feat`: Add, update, or remove feature flags
- 💫 `ui`: Add or update animations and transitions
- ⚰️ `refactor`: Remove dead code
- 🦺 `feat`: Add or update code related to validation
- ✈️ `feat`: Improve offline support

## Guidelines

- Present tense, imperative mood (e.g., "add feature" not "added feature")
- Keep first line under 72 characters
- Atomic commits: each commit should serve a single purpose
- Split large changes into separate commits by concern

## Splitting Criteria

Split commits when changes involve:
1. Different concerns or unrelated parts of the codebase
2. Different types of changes (features, fixes, refactoring)
3. Different file types (source code vs documentation)
4. Logically independent changes
5. Very large changes that would be clearer if broken down

## Examples

Good commit messages:
- ✨ feat: add user authentication system
- 🐛 fix: resolve memory leak in rendering process
- 📝 docs: update API documentation with new endpoints
- ♻️ refactor: simplify error handling logic in parser
- 🚨 fix: resolve linter warnings in component files
- 🧑‍💻 chore: improve developer tooling setup process
- 👔 feat: implement business logic for transaction validation
- 🩹 fix: address minor styling inconsistency in header
- 🚑️ fix: patch critical security vulnerability in auth flow
- 🎨 style: reorganize component structure for better readability
- 🔥 fix: remove deprecated legacy code
- 🦺 feat: add input validation for user registration form
- 💚 fix: resolve failing CI pipeline tests
- 📈 feat: implement analytics tracking for user engagement
- 🔒️ fix: strengthen authentication password requirements
- ♿️ feat: improve form accessibility for screen readers
