# fix/266-complete-path-fallback-refactor

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Complete the DOTLY_PATH fallback refactor started in #255: replace 139 remaining
occurrences of `${SLOTH_PATH:-${DOTLY_PATH:-}}` with `${SLOTH_PATH:-}` in 54 files.
The fallback is redundant because `_main.sh` (line 8-10) and `init-sloth.sh`
(line 76-78) already resolve `SLOTH_PATH` from `DOTLY_PATH` before any downstream
code runs. The architecture doc must also be updated to reflect the canonical
pattern.

## Issue

`#266` — tracked issue. Required. The PR must close it.

## Branch

`fix/266-complete-path-fallback-refactor`

## Root cause

Issue #255 refactored 53 occurrences in 13 core library files but left 139
occurrences in 54 context scripts, standalone scripts, entry points, shell
integration files, and templates. These files still use the dual-variable
fallback pattern `${SLOTH_PATH:-${DOTLY_PATH:-}}` even though:

1. `scripts/core/src/_main.sh:8-10` — early resolution block resolves both
   variables from each other before any library is loaded.
2. `shell/init-sloth.sh:76-78` — compatibility layer resolves both variables
   before sourcing shell integration files.
3. `bin/dot:12-20` — entry point resolves `SLOTH_PATH` from `realpath` if unset,
   then sources `_main.sh`.
4. `bin/sloth:10` — entry point checks `SLOTH_PATH` and sources `_main.sh`.

Evidence:
- `grep -rc 'SLOTH_PATH:-${DOTLY_PATH' scripts/ bin/ restorer installer shell/ dotfiles_template/` → 139 occurrences in 54 files
- `scripts/core/src/_main.sh:8-10` — `SLOTH_PATH="${SLOTH_PATH:-${DOTLY_PATH:-}}"` / `DOTLY_PATH="${DOTLY_PATH:-${SLOTH_PATH:-}}"`
- `shell/init-sloth.sh:76-78` — same resolution block
- `docs/architecture/ARCHITECTURE.md:32` — still references stale pattern

## Scope

### In scope

The smallest change set that closes the issue.

1. Replace `${SLOTH_PATH:-${DOTLY_PATH:-}}` → `${SLOTH_PATH:-}` in 54 files
   across `scripts/`, `bin/`, `restorer`, `installer`, `shell/`,
   `dotfiles_template/`.
2. Update `docs/architecture/ARCHITECTURE.md:32` — replace stale pattern with
   canonical `${SLOTH_PATH:-}`.
3. Run `shfmt` on all modified files to ensure formatting compliance.

### Out of scope

- `shell/init-sloth.sh:76-78` — compatibility layer, already preserved in #255.
- `scripts/core/src/_main.sh:8-10` — early resolution block, added in #255.
- `dotfiles_template/README.md` — documentation reference, not code. The
  fallback pattern in the README is illustrative for users setting up manually.
  Pointer: update in a separate docs cleanup if needed.
- Adding `set -euo pipefail` to scripts that lack it — tracked in #269.

## Impact

- Modules/files touched: 54 files across `scripts/`, `bin/`, `restorer`,
  `installer`, `shell/`, `dotfiles_template/`, plus `docs/architecture/ARCHITECTURE.md`.
- Blast radius: medium — touches entry points (`bin/dot`, `bin/sloth`, `bin/up`),
  context scripts, shell integration, and bootstrap scripts (`restorer`,
  `installer`). If `SLOTH_PATH` is not resolved before these files run, they will
  fail. However, all files either (a) source `_main.sh` first, (b) are loaded by
  `init-sloth.sh` which resolves it, or (c) are entry points that resolve it
  themselves.
- Detection lead time: immediate — broken `SLOTH_PATH` resolution would cause
  `bin/dot` to fail on every invocation.

## Rules that must never be violated

- `bin/dot` and `bin/sloth` are entry points that resolve `SLOTH_PATH` before
  sourcing `_main.sh`. The fallback pattern in these files handles the case where
  neither variable is set — the entry point resolves it from `realpath`. After
  the entry point resolves `SLOTH_PATH`, the fallback is redundant. BUT: the
  fallback in the entry point's initial check (`if [[ -z "${SLOTH_PATH:-${DOTLY_PATH:-}}" ]]`)
  must be preserved until AFTER the resolution block, because at that point
  neither variable may be set. Only the fallback in lines AFTER the resolution
  block should be replaced.
- `restorer` and `installer` are standalone scripts that resolve `SLOTH_PATH`
  themselves (lines 324-325 and 313-314). The fallback in lines BEFORE the
  resolution block must be preserved. Only lines AFTER should be replaced.
- `shell/init-sloth.sh:76-78` must NOT be modified (compatibility layer).
- `scripts/core/src/_main.sh:8-10` must NOT be modified (early resolution block).
- `shfmt` formatting: `shfmt -ln bash -sr -ci -i 2 -d` must pass.
- `shellcheck` static analysis must pass.

## Risks

- **Operational**: `restorer` and `installer` are bootstrap scripts that run
  before `_main.sh` is available. They resolve `SLOTH_PATH` themselves. If the
  fallback is removed from lines BEFORE their resolution block, they will fail
  on systems where neither `SLOTH_PATH` nor `DOTLY_PATH` is set. Mitigation:
  only replace fallback in lines AFTER the resolution block in these files.
- **Operational**: `dotfiles_template/` files are copied to user dotfiles. They
  may run in contexts where `init-sloth.sh` has not yet resolved `SLOTH_PATH`
  (e.g. a user manually running a script before sourcing `.zshrc`). Mitigation:
  `dotfiles_template/bin/sdot` sources `.bashrc` first (which loads
  `init-sloth.sh`), `dotfiles_template/scripts/hello/world` sources `_main.sh`
  first. Both are safe to refactor.
- **Security**: n/a — no auth, secrets, or PII.
- **Compliance**: n/a.

## Acceptance criteria

- [ ] 0 occurrences of `${SLOTH_PATH:-${DOTLY_PATH:-}}` remain in `scripts/`,
      `bin/`, `shell/` (excluding `init-sloth.sh:76-78`)
- [ ] `restorer` and `installer` fallback patterns replaced only AFTER their
      resolution blocks (lines 324-325 and 313-314 respectively)
- [ ] `docs/architecture/ARCHITECTURE.md:32` updated to canonical `${SLOTH_PATH:-}`
- [ ] `shell/init-sloth.sh:76-78` unchanged (compatibility layer)
- [ ] `scripts/core/src/_main.sh:8-10` unchanged (early resolution block)
- [ ] `bash scripts/self/static_analysis` passes clean
- [ ] `dot core lint` passes clean
- [ ] `make test` passes (48+ existing tests)
- [ ] CI env simulation passes: `env -u SLOTH_PATH DOTLY_PATH=<repo> bash scripts/self/static_analysis`
- [ ] Manual verification: `bin/dot --help` works with only `DOTLY_PATH` set

## Rollback

Revert the PR. No data-side cleanup needed — the refactor only changes variable
reference patterns, no state is modified.

## Effort

**S** — 54 files, mechanical replacement with 2 exceptions (restorer/installer
pre-resolution lines). ≤ 4h including verification.

## Impact (extra sections)

- Layers: all layers — entry points, context scripts, shell integration,
  bootstrap scripts, templates.
- Blast radius: medium — touches critical paths but the resolution blocks
  already handle the fallback.
- Detection lead time: immediate — any broken path resolution fails on first
  invocation.

## Rules that must never be violated (extra)

- `bin/dot` and `bin/sloth` entry points: preserve fallback in the initial check
  (before resolution block), replace in lines after.
- `restorer` and `installer`: preserve fallback before their resolution blocks
  (lines 324-325 and 313-314), replace after.
- `shell/init-sloth.sh:76-78` and `_main.sh:8-10` — DO NOT MODIFY.
- `shfmt -ln bash -sr -ci -i 2 -d` must pass on all modified files.
- `shellcheck` must pass (CI env: `DOTLY_PATH` set, `SLOTH_PATH` unset).

## Operational risks

- `restorer`/`installer` run before `_main.sh` — must preserve pre-resolution
  fallback.
- `dotfiles_template/` files run in user environments — verified safe (all source
  `_main.sh` or `.bashrc` first).
- CI sets `DOTLY_PATH` only (not `SLOTH_PATH`) — `_main.sh` resolves it. Must
  verify with `env -u SLOTH_PATH DOTLY_PATH=<repo>`.

## Security risks

n/a — no auth, secrets, PII, or webhooks.

## Compliance touchpoints

n/a.

## Affected docs

- `docs/architecture/ARCHITECTURE.md` — section "Context scripts must source
  `_main.sh` first": replace `${SLOTH_PATH:-${DOTLY_PATH:-}}` with `${SLOTH_PATH:-}`.
- `docs/fix/README.md` — update entry status from `pending` to `done` when PR opens.

## Observability

- Before: scripts use `${SLOTH_PATH:-${DOTLY_PATH:-}}` (dual fallback).
- After: scripts use `${SLOTH_PATH:-}` (single canonical variable).
- Failure mode: if `SLOTH_PATH` is not resolved, scripts fail immediately with
  "file not found" — detectable on first run.

## Cross-issue notes

- #255 — prerequisite, already merged. This fix completes the refactor.
- #269 (set -euo pipefail migration) — parallel, no overlap. Some files in #266
  may also be in #269, but the changes are independent (variable reference vs
  shell options).
- #265 (gem false positive) — parallel, no overlap (different file).

## Effort

**S** — 54 files, mechanical replacement with 2 exceptions. ≤ 4h.

## Decisions made during drafting

- `dotfiles_template/README.md` — left out of scope. It's documentation showing
  users how to manually install. The fallback pattern is illustrative.
- `dotfiles_template/bin/sdot` — safe to refactor: sources `.bashrc` first which
  loads `init-sloth.sh` which resolves `SLOTH_PATH`.
- `dotfiles_template/scripts/hello/world` — safe to refactor: sources `_main.sh`
  first.
- `dotfiles_template/shell/zsh/.zshrc` — safe to refactor: loads `init-sloth.sh`
  which resolves `SLOTH_PATH`.
- `bin/up` — uses `#!/usr/bin/env sloth` shebang which sources `_main.sh`. Safe
  to refactor.
- `shell/bash/completions/_dot` and `shell/zsh/completions/_dot` — loaded by
  shell after `init-sloth.sh` resolves `SLOTH_PATH`. Safe to refactor.
- `shell/init.scripts/autoupdate` — loaded by `init-sloth.sh` after resolution.
  Safe to refactor.
- `shell/zsh/themes/*` — loaded by zsh prompt system after `init-sloth.sh`.
  Safe to refactor.
- `shell/zsh/bindings/dot.zsh` — loaded after `init-sloth.sh`. Safe to refactor.
- `bin/dot` — preserve fallback in initial check (lines 12-13), replace in lines
  after resolution block (line 20+).
- `bin/sloth` — preserve fallback in initial check (line 10), replace in line 12+
  (after `_main.sh` is sourced).
- `restorer` — preserve fallback before line 324, replace after.
- `installer` — preserve fallback before line 313, replace after.
