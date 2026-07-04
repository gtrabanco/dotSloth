# Fix #233 — Auto-updater broken

## Issue
[#233](https://github.com/gtrabanco/dotSloth/issues/233)

## Root Causes

### Bug 1 (Critical): `${disable:-enable}` default executes bash builtin
**File:** `scripts/core/update:27`
**Code:** `if ${disable:-enable}; then`
**Problem:** When `--disable` is not passed, the default value is the string `enable`.
Bash executes it as a command (the `enable` builtin), which always returns 0.
This means the disable path (`touch .sloth_force_current_version; exit 0`) runs
on every invocation, blocking all updates unconditionally.

**Fix:** Change default to `false`: `if ${disable:-false}; then`

### Bug 2 (Medium): Stale `sloth.git` fallback URLs
**Files:** `scripts/core/src/sloth_update.sh` (4 sites), `scripts/core/version` (1 site)
**Problem:** Five fallback URLs reference `github.com:gtrabanco/sloth.git`, a
repository that no longer exists (renamed to `dotSloth`). These are last-resort
fallbacks behind `SLOTH_DEFAULT_GIT_SSH_URL` (which is correct), so they only
fire when the env var is unset AND the gitmodules file is absent — rare in
practice but silent failure when they do.

**Fix:** Replace all `sloth.git` fallbacks with `dotSloth.git`.

### Bug 3 (Low): Undeclared `branch` variable in `sloth_update::sloth_update()`
**File:** `scripts/core/src/sloth_update.sh:241`
**Code:** `branch="${3:-${SLOTH_DEFAULT_BRANCH:-main}}"`
**Problem:** `branch` is assigned but not declared in the `local` statement at
line 238 (`local remote url default_branch head_branch force_update updated_version`).
Under `set -u` this can leak the variable to the global scope.

**Fix:** Add `branch` to the `local` declaration.

## Scope
- `scripts/core/update` — Bug 1
- `scripts/core/src/sloth_update.sh` — Bugs 2 + 3
- `scripts/core/version` — Bug 2 (one site)

## Verification
```bash
PROJECT_ROOT=/Users/gtrabanco/MyProjects/dotSloth \
SLOTH_PATH=/Users/gtrabanco/MyProjects/dotSloth \
DOTLY_PATH=/Users/gtrabanco/MyProjects/dotSloth \
bash scripts/self/static_analysis

dot core lint

make test
```

## Size: S
