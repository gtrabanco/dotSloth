# fix/265-gem-update-false-positive

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

`gem::update_apps` silently reports "Already up-to-date" when `gem outdated` fails
with a non-zero exit code (e.g. broken native extensions on macOS Apple Silicon).
The fix makes the function check the exit code and surface the error instead of
showing a false positive.

## Issue

`#265` — tracked issue. Required. The PR must close it.

## Branch

`fix/265-gem-update-false-positive`

## Root cause

`scripts/package/src/package_managers/gem.sh:51` captures stdout only:

```bash
outdated=$(gem outdated)
```

When `gem outdated` fails (exit 1), stdout is empty and stderr contains the error
(openssl/psych LoadError). Line 53 then checks `if [ -n "$outdated" ]` — empty
stdout means "no updates", but the real condition is "command failed". The exit
code is never checked, so the user sees "Already up-to-date" instead of an error.

Evidence:
- `gem.sh:51` — `outdated=$(gem outdated)` (stdout only, no exit code check)
- `gem.sh:53` — `if [ -n "$outdated" ]` (empty = "up-to-date", but actually error)
- `gem outdated 2>/dev/null` → exit 1, empty stdout (reproduced on macOS Apple Silicon)
- `gem outdated 2>&1` → openssl/psych LoadError (x86_64 vs arm64)

## Scope

### In scope

The smallest change set that closes the issue.

1. `scripts/package/src/package_managers/gem.sh:48-67` — `gem::update_apps()`:
   capture `gem outdated` exit code, distinguish "no updates" from "command
   failed", show error message on failure.

### Out of scope

- Fixing the underlying macOS system Ruby issue (x86_64 gems on arm64) — that is
  a system-level problem, not a dotSloth bug. Pointer: document in
  `scripts/mac/fix_gem_openssl` or a new wiki page.
- Adding `gem::self_update` exit code handling — `self_update` already pipes to
  `log::file` and does not show a false positive.
- Refactoring other package managers (brew, npm, dnf) — they use different
  patterns (`readarray`, `tail -n +2`) and are tracked separately if needed.

## Impact

- Modules/files touched: `scripts/package/src/package_managers/gem.sh` (1 file,
  ~10 lines changed in `gem::update_apps`).
- Blast radius: low — only affects `gem` package manager output during `up`.
  Other package managers are untouched. If the fix is wrong, the worst case is
  showing an error message when there are no updates (false negative), which is
  less harmful than the current false positive.
- Detection lead time: immediate — user sees the error message during `dot up`
  instead of a silent "Already up-to-date".

## Rules that must never be violated

- `set -euo pipefail` is not used in package manager modules (they are sourced
  by `bin/up` which sets it). The fix must not introduce `set -e` in `gem.sh`
  because it would break the sourcing pattern.
- Package manager functions follow the `name::function()` convention.
- `output::answer` is used for success messages, `output::error` for errors.
- The function must return 1 when `gem` is not available (line 49, unchanged).

## Risks

- **Operational**: n/a — no scheduled jobs, queues, or caches involved.
- **Security**: n/a — no auth, secrets, or PII.
- **Compliance**: n/a.

## Acceptance criteria

- [ ] `gem::update_apps` checks the exit code of `gem outdated` (unit test:
      `tests/package/gem.bats`)
- [ ] When `gem outdated` exits non-zero, an error message is shown (not
      "Already up-to-date") (unit test: `tests/package/gem.bats`)
- [ ] When `gem outdated` exits 0 with empty stdout, "Already up-to-date" is
      shown (unit test: `tests/package/gem.bats`)
- [ ] When `gem outdated` exits 0 with non-empty stdout, updates proceed as
      before (unit test: `tests/package/gem.bats`)
- [ ] `bash scripts/self/static_analysis` passes clean
- [ ] `dot core lint` passes clean
- [ ] `make test` passes (48+ existing tests + new gem tests)
- [ ] Manual verification: `dot up` with broken system Ruby shows error, not
      "Already up-to-date"

## Rollback

Revert the PR. No data-side cleanup needed — the fix only changes output
messaging, no state is modified.

## Effort

**XS** — 1 file, ~10 lines changed, 1 new test file. ≤ 1h.

## Impact (extra sections)

- Layers: package manager adapter (`scripts/package/src/package_managers/gem.sh`).
- Blast radius: user-visible output during `dot up` for `gem` manager only.

## Rules that must never be violated (extra)

- Package manager modules are sourced (not executed standalone) — no `set -e`.
- `output::answer` for success, `output::error` for errors.
- Function naming: `gem::function_name()`.

## Operational risks

n/a — no scheduled jobs, queues, caches, or external adapters beyond `gem` CLI.

## Security risks

n/a — no auth, secrets, PII, or webhooks.

## Compliance touchpoints

n/a.

## Affected docs

- `docs/fix/README.md` — update entry status from `pending` to `done` when PR opens.

## Observability

- Before: `dot up` shows `♦️ gem > Already up-to-date` even when `gem outdated` fails.
- After: `dot up` shows `♦️ gem > ⚠️ Error checking for updates (exit code N). See \`dot self debug\` for details.` when `gem outdated` fails.
- The error message is user-visible and actionable.

## Cross-issue notes

- #267 (tests for sloth_update.sh) — parallel, no overlap.
- #269 (set -euo pipefail migration) — `gem.sh` does not use `set -euo pipefail`
  (sourced module), so #269 does not affect this fix.
- #235 (up parse updates) — already fixed, `gem.sh` was part of that fix (added
  `local outdated` on line 50). This fix builds on that.

## Effort

**XS** — 1 file, ~10 lines changed, 1 new test file. ≤ 1h.

## Decisions made during drafting

- Error message format: `output::error "Error checking for updates (exit code $?). See \`dot self debug\` for details."` — follows the pattern used by `update_all_error` in `bin/up:46`.
- Capture stderr to log: `outdated=$(gem outdated 2>&1)` would mix stderr into the
  outdated list and break parsing. Instead, keep `outdated=$(gem outdated 2>&1)`
  but check exit code first, then parse only if exit 0. Alternative: capture
  stdout and stderr separately. Decision: capture stdout only (as before), check
  exit code, and let stderr flow to the log via the calling context.
- New test file: `tests/package/gem.bats` — follows the existing pattern
  (`tests/package/brew.bats`, `tests/package/dnf.bats`).
