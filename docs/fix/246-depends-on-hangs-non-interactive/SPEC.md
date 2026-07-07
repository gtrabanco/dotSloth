# Fix #246 — script::depends_on hangs in non-interactive contexts

## Problem

`script::depends_on` calls `output::question` which calls `read -r` when
`DOTLY_ENV` is not `CI` and `DOTLY_INSTALLER` is not `true`. In non-interactive
contexts (cron jobs, tmux sessions without a TTY, SSH without pseudo-terminal),
`read` blocks indefinitely waiting for input that never arrives.

## Root cause

`output::question` (line 63-68 of `scripts/core/src/output.sh`) checks for
`DOTLY_ENV=CI` and `DOTLY_INSTALLER=true`, but does not check whether stdin
is actually a TTY (`[[ -t 0 ]]`). Any non-interactive context that doesn't
set one of those env vars will hang on `read`.

## Fix

Add a `[[ -t 0 ]]` check to `output::question` — if stdin is not a terminal,
default to `"y"` (auto-install) instead of calling `read`. This is the same
behavior as the existing `DOTLY_ENV=CI` path.

## Files

- `scripts/core/src/output.sh` — add `[[ -t 0 ]]` guard to `output::question`

## Tests

No new tests needed — `output::question` is tested in `tests/core/output.bats`
but those tests run in non-interactive mode (bats pipes stdin), so they already
exercise the non-TTY path. The fix makes that path explicit instead of relying
on `DOTLY_ENV`.
