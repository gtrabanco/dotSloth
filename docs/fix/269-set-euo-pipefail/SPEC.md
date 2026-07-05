# Fix: Migrate remaining scripts to set -euo pipefail

## Issue

[#269](https://github.com/gtrabanco/dotSloth/issues/269) — Migrate remaining scripts to set -euo pipefail

## Problem

The architecture doc mandates `set -euo pipefail` for all bash scripts, and CI
enforces it via shellcheck. Several entry-point scripts lack it. Scripts that
source `_main.sh` (via the sloth shebang or direct `source`) already inherit
`set -euo pipefail` from `_main.sh`, but standalone entry points need it
explicitly.

## Scope

Add `set -euo pipefail` after the shebang in 7 standalone entry-point scripts,
and fix 1 script that has `set -uo pipefail` (missing `-e`).

### Files to modify

| File | Change |
|------|--------|
| `bin/$` | Add `set -euo pipefail` after shebang |
| `bin/open` | Add `set -euo pipefail` after shebang |
| `bin/pbcopy` | Add `set -euo pipefail` after shebang |
| `bin/pbpaste` | Add `set -euo pipefail` after shebang |
| `scripts/core/short_pwd` | Add `set -euo pipefail` after shebang |
| `scripts/core/migration` | Change `set -uo pipefail` → `set -euo pipefail` |
| `scripts/generator/recipe` | Add `set -euo pipefail` after shebang |
| `scripts/generator/script` | Add `set -euo pipefail` after shebang |

### Files NOT modified (intentionally)

- `scripts/core/src/*.sh` — sourced by `_main.sh`, inherits from it
- `scripts/package/src/package_managers/*.sh` — sourced via `dot::load_library`
- `scripts/package/src/recipes/*.sh` — sourced via `dot::load_library`
- `scripts/symlinks/src/*.sh` — sourced by symlinks entry points
- `scripts/init/src/init.sh` — sourced by init entry points
- `scripts/generator/src/templates/*` — templates, not executed
- Scripts that source `_main.sh` directly (already inherit `set -euo pipefail`)

## Acceptance criteria

1. All 8 target files have `set -euo pipefail` after their shebang line
2. `bash scripts/core/lint` passes
3. `bash scripts/self/static_analysis` passes
4. `make test` passes
5. No behavioral change — adding `set -e` to scripts that previously lacked it
   may surface latent errors; if any surface, they must be fixed in this fix

## Risk

Low — mechanical addition. Scripts that source `_main.sh` already run under
`set -euo pipefail`, so this makes the explicit declaration match the runtime
reality. The only risk is if a script has a command that fails non-fatally
under `set -e` where it previously didn't; such cases will be caught by the
test gate.

## Branch

`fix/269-set-euo-pipefail`
