# Fix #255 — Reconcile DOTLY_PATH and SLOTH_PATH variable compatibility

## Issue
[#255](https://github.com/gtrabanco/dotSloth/issues/255)

## Approach: Option A — Single canonical variable

`SLOTH_PATH` is the canonical variable. All `${SLOTH_PATH:-${DOTLY_PATH:-}}`
fallback patterns are replaced with `$SLOTH_PATH`. The compatibility mechanism
in `shell/init-sloth.sh` (lines 76-78) already sets `SLOTH_PATH` from
`DOTLY_PATH` if the former is unset, so `DOTLY_PATH` remains as a
backward-compat alias.

## Scope

53 occurrences across 13 files:

| File | Count |
|------|-------|
| shell/init-sloth.sh | 13 |
| scripts/core/src/sloth_update.sh | 9 |
| scripts/core/src/dot.sh | 8 |
| scripts/package/src/recipes/nvm.sh | 4 |
| scripts/core/src/dotly.sh | 4 |
| scripts/core/src/package.sh | 3 |
| scripts/core/src/files.sh | 3 |
| dotfiles_template/shell/aliases.sh | 3 |
| shell/bash/init.sh | 2 |
| scripts/init/src/init.sh | 1 |
| scripts/core/src/script.sh | 1 |
| scripts/core/src/registry.sh | 1 |
| scripts/core/src/_main.sh | 1 |

## Changes

1. Replace all `${SLOTH_PATH:-${DOTLY_PATH:-}}` with `${SLOTH_PATH:-}`
   (preserving the `:-` for empty-string safety, but dropping the DOTLY_PATH
   fallback since init-sloth.sh guarantees SLOTH_PATH is set).
2. Keep `shell/init-sloth.sh` lines 76-78 as-is — this is the compatibility
   layer that sets both variables from whichever is available.
3. Do NOT remove `DOTLY_PATH` references entirely — it's still set as an alias
   for backward compatibility. Only remove the inline fallback pattern.

## Risk Assessment

- **Low risk**: The init-sloth.sh compatibility layer runs before any script
  that uses SLOTH_PATH, guaranteeing it's set.
- **Tests**: All tests already use SLOTH_PATH directly (no fallback), so no
  test changes needed.
- **Backward compat**: Users who set DOTLY_PATH in their shell config will
  still work because init-sloth.sh copies it to SLOTH_PATH.

## Verification
```bash
export PROJECT_ROOT=/Users/gtrabanco/MyProjects/dotSloth
export SLOTH_PATH=/Users/gtrabanco/MyProjects/dotSloth
export DOTLY_PATH=/Users/gtrabanco/MyProjects/dotSloth
bash scripts/self/static_analysis
bash scripts/self/lint
make test
```

## Size: M
## Auto-merge: NO — requires manual review (tech-debt refactor, 53 changes across 13 files)
