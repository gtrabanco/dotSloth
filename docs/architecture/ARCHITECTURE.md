# Architecture

## Pattern

**Modular monolith with context-based namespacing.** dotSloth is a Bash framework organized around the concept of "contexts" — top-level directories under `scripts/` that group related commands. The entry point (`bin/dot`) resolves `<context> <script> [args]` and delegates execution.

This is not a layered architecture in the traditional sense; it's a command-dispatch pattern where:
- Core libraries provide reusable functions (sourced, not executed).
- Context scripts are executable commands invoked via `dot <context> <script>`.
- User dotfiles (`$DOTFILES_PATH/scripts/`) can override or extend core contexts.

## Modules / layers

| Module / layer | Responsibility | May depend on | Must NOT depend on |
|---|---|---|---|
| `bin/dot` | Entry point; resolves `SLOTH_PATH`, sources `_main.sh`, dispatches to context scripts | `scripts/core/src/_main.sh` | User dotfiles scripts directly |
| `scripts/core/src/` | Core libraries (sourced): `dot.sh`, `git.sh`, `package.sh`, `output.sh`, `log.sh`, `platform.sh`, etc. | Each other (via `dot::load_library`) | User dotfiles scripts; context scripts |
| `scripts/core/` | Core context scripts (executable): `install`, `lint`, `loader`, `update`, `version`, etc. | `scripts/core/src/` libraries | — |
| `scripts/<context>/` | Other core contexts: `dotfiles/`, `init/`, `mac/`, `package/`, `script/`, `self/`, `symlinks/` | `scripts/core/src/` libraries | — |
| `dotfiles_template/` | Template for user dotfiles repo; copied on install | — | `scripts/core/` internals (uses `dot` CLI as external interface) |
| `shell/` | Shell configuration: `zsh/`, `bash/`, `init.scripts/`, `aliases.sh`, `exports.sh`, `paths.sh` | — | `scripts/core/src/` (loaded by loader, not sourced directly) |
| `symlinks/` | Symlink definitions applied/restored by `dot symlinks` | — | — |
| `installer` / `restorer` | Standalone bootstrap scripts (curl|bash) | `git`, `bash` | `scripts/core/src/` (must be self-contained) |

## Dependency rules (invariants)

- **Core libraries (`scripts/core/src/*.sh`) must not source or execute user dotfiles scripts.** They are the foundation; user scripts depend on them, never the reverse.
- **Core libraries must not depend on context scripts** (`scripts/core/install`, `scripts/package/add`, etc.). Libraries are sourced; context scripts are dispatched.
- **Context scripts must source `_main.sh` first** before using any core library function. The standard header is:
  ```bash
  #shellcheck disable=SC1091
  . "${SLOTH_PATH:-}/scripts/core/src/_main.sh"
  ```
- **The `installer` and `restorer` scripts must be self-contained** — they run before dotSloth is installed and must not depend on `scripts/core/src/` or any `SLOTH_PATH` resolution.
- **Package manager wrappers** (`scripts/package/src/package_managers/*.sh`) must implement the standard interface: `dump`, `install`, `update_all`, `cleanup`, `which` (where applicable). New wrappers must follow the `brew.sh` pattern.
- **Recipes** (`scripts/package/src/recipes/*.sh`) must implement: `install`, `update` (if applicable), and `info` (if applicable). They may use package managers but must not be used as package managers themselves.
- **Init scripts** (`shell/init.scripts/`) are sourced at the end of the shell initializer and must be idempotent and fast. They must not depend on core libraries being loaded (they run after the loader, but must degrade gracefully).
- **`set -euo pipefail`** is mandatory in all standalone/executable scripts. Sourced library files (`scripts/core/src/*.sh`) intentionally omit it — `set -e` would propagate to the caller's shell on any function failure, breaking the interactive experience. The entry point (`bin/dot`) sets it, and it applies for the duration of each command invocation.
- **No bashisms in zsh-targeted code.** Scripts under `shell/zsh/` may use zsh syntax; scripts under `shell/bash/` must be bash-compatible. Core scripts must be bash-compatible (shfmt lints as bash).

## Diagram

```
┌─────────────────────────────────────────────────────┐
│                   bin/dot (entry)                    │
│  Resolves SLOTH_PATH → sources _main.sh → dispatches │
└──────────────────────┬──────────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │  scripts/core/src/      │
          │  (_main.sh sources all) │
          │  dot.sh  git.sh  pkg.sh │
          │  output.sh  log.sh  ... │
          └────────────┬────────────┘
                       │ (libraries used by)
     ┌─────────────────┼─────────────────────┐
     │                 │                     │
┌────▼─────┐  ┌───────▼────────┐  ┌────────▼────────┐
│ scripts/  │  │ scripts/       │  │ dotfiles_template│
│ core/     │  │ <context>/     │  │ (user's scripts) │
│ (cmds)    │  │ (package, init)│  │ $DOTFILES_PATH   │
└───────────┘  └────────────────┘  └──────────────────┘

┌──────────────────────────────────────────────────────┐
│  installer / restorer (standalone, self-contained)    │
│  curl|bash → git clone → make install → dot symlinks  │
└──────────────────────────────────────────────────────┘
```
