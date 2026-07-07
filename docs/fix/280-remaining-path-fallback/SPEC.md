# fix/280-remaining-path-fallback

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Replace 6 remaining redundant `${SLOTH_PATH:-${DOTLY_PATH:-}}` fallback patterns
in `scripts/init/{enable,disable,status}` with `${SLOTH_PATH:-}`. These scripts
are dispatched via `bin/dot` which sets `SLOTH_PATH` in the environment before
invocation (line 190), making the `DOTLY_PATH` fallback redundant.

## Issue

`#280` — tracked issue. Required. The PR must close it.

## Branch

`fix/280-remaining-path-fallback`

## Root cause

Issue #255 and #266 refactored most `DOTLY_PATH` fallback patterns but left 15
occurrences. Of those, 6 are in context scripts (`scripts/init/`) that are
dispatched via `bin/dot` which already exports `SLOTH_PATH` at line 190:

```bash
SLOTH_PATH="$SLOTH_PATH" DOTLY_PATH="${SLOTH_PATH:-}" DOTFILES_PATH="${DOTFILES_PATH:-}" "$script_full_path" "$@"
```

The remaining 9 occurrences are structurally necessary:
- `scripts/core/src/_main.sh:10` — compatibility layer (must NOT change)
- `bin/dot:12,13` — pre-resolution entry point (must NOT change)
- `bin/sloth:10,13` — pre-resolution entry point (must NOT change)
- `restorer:325` — standalone bootstrap (must NOT change)
- `installer:314` — standalone bootstrap (must NOT change)
- `shell/init-sloth.sh:77` — compatibility layer (must NOT change)

## Scope

### In scope

Replace 6 occurrences across 3 files:

| File | Lines | Change |
|------|-------|--------|
| `scripts/init/enable` | 5, 8 | `${SLOTH_PATH:-${DOTLY_PATH:-}}` → `${SLOTH_PATH:-}` |
| `scripts/init/disable` | 5, 8 | `${SLOTH_PATH:-${DOTLY_PATH:-}}` → `${SLOTH_PATH:-}` |
| `scripts/init/status` | 5, 8 | `${SLOTH_PATH:-${DOTLY_PATH:-}}` → `${SLOTH_PATH:-}` |

### Out of scope

- `scripts/core/src/_main.sh:10` — compatibility layer, intentionally preserved
- `bin/dot:12,13` — entry point pre-resolution fallback, structurally necessary
- `bin/sloth:10,13` — entry point pre-resolution fallback, structurally necessary
- `restorer:325` — standalone bootstrap, runs before `_main.sh` is available
- `installer:314` — standalone bootstrap, runs before `_main.sh` is available
- `shell/init-sloth.sh:77` — compatibility layer, intentionally preserved
- Adding `set -euo pipefail` to scripts that lack it — tracked in #269

## Impact

- Modules/files touched: 3 files (`scripts/init/enable`, `scripts/init/disable`,
  `scripts/init/status`), 2 lines each.
- Blast radius: low — these are context scripts dispatched via `bin/dot` which
  already resolves `SLOTH_PATH` before invocation.
- Detection lead time: immediate — if `SLOTH_PATH` is not set, the guard check
  on line 5 exits with code 1, which `bin/dot` propagates.

## Rules that must never be violated

- `shell/init-sloth.sh:76-78` must NOT be modified (compatibility layer).
- `scripts/core/src/_main.sh:8-10` must NOT be modified (early resolution block).
- `bin/dot` and `bin/sloth` entry points: preserve fallback in initial check
  (before resolution block).
- `restorer` and `installer`: preserve fallback before their resolution blocks.
- `shfmt -ln bash -sr -ci -i 2 -d` must pass on all modified files.
- `shellcheck` must pass.
- Context scripts must source `_main.sh` first (ARCHITECTURE.md:29-33).

## Risks

- **Operational**: n/a — the scripts are only invoked via `bin/dot` which sets
  `SLOTH_PATH` in the environment. The guard check on line 5 provides a safety
  net: if `SLOTH_PATH` is unset, the script exits immediately.
- **Security**: n/a — no auth, secrets, PII.
- **Compliance**: n/a.
- **Backward compatibility**: n/a — `DOTLY_PATH` is still set as an alias by
  `init-sloth.sh` for users who reference it in their shell config.

## Acceptance criteria

- [ ] 0 occurrences of `${SLOTH_PATH:-${DOTLY_PATH:-}}` remain in
      `scripts/init/{enable,disable,status}`
- [ ] `scripts/core/src/_main.sh:10` unchanged
- [ ] `shell/init-sloth.sh:77` unchanged
- [ ] `bin/dot:12,13` unchanged
- [ ] `bin/sloth:10,13` unchanged
- [ ] `restorer:325` unchanged
- [ ] `installer:314` unchanged
- [ ] `bash scripts/self/static_analysis` passes clean
- [ ] `bash scripts/core/lint` passes clean
- [ ] `make test` passes (48+ existing tests)

## Rollback

Revert the PR. No data-side cleanup needed — the refactor only changes variable
reference patterns, no state is modified.

## Effort

**XS** — 3 files, 6 lines, mechanical replacement. ≤ 1h including verification.

## Observability

- Before: `scripts/init/{enable,disable,status}` use `${SLOTH_PATH:-${DOTLY_PATH:-}}`.
- After: `scripts/init/{enable,disable,status}` use `${SLOTH_PATH:-}`.
- Failure mode: if `SLOTH_PATH` is not resolved, the guard check on line 5
  exits immediately — detectable on first invocation.

## Cross-issue notes

- #255 — prerequisite, already merged. This fix continues the refactor.
- #266 — prerequisite, already merged. This fix continues the refactor.
- #269 (set -euo pipefail migration) — parallel, no overlap. These scripts
  already have `set -euo pipefail`.
- #274 (dotly.bats test failure) — unrelated, different issue.
- #275 (CI bats tests) — unrelated, different issue.

## Decisions made during drafting

- `scripts/core/install:12` — left out of scope. It has additional logic with
  `BASH_SOURCE` that derives `SLOTH_PATH` from the script's own path. The
  fallback pattern there is structurally different and should be evaluated
  separately if needed.
- Only context scripts dispatched via `bin/dot` are targeted. Standalone scripts
  (`restorer`, `installer`) and entry points (`bin/dot`, `bin/sloth`) retain
  their fallback patterns because they resolve `SLOTH_PATH` before `_main.sh`
  is available.
