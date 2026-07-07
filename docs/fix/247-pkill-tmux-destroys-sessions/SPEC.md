# Fix #247 — pkill -f tmux destroys all system sessions

## Problem

`bin/up` line 55 executes `pkill -f tmux || true` after updating packages in
non-split mode. This kills **all** tmux sessions on the system, not just any
session created by `up --split`.

The `--split` path exits at line 31 (`exit 0`), so the `pkill` at line 55 only
runs in non-split mode — where no tmux session was created by `up` at all.

## Root cause

The `pkill -f tmux` was likely added as cleanup for the split mode, but it
runs unconditionally in the non-split path because the split path already
exited. It destroys every tmux process matching "tmux" — including sessions
the user created independently.

## Fix

Remove the unconditional `pkill -f tmux` block (lines 54-56). In split mode,
the tmux session is self-contained and exits when its command completes. If
targeted cleanup is needed in split mode, it should use `tmux kill-session -t
"$SESSION_NAME"` inside the split path before `exit 0`, not a blanket `pkill`
in the non-split path.

## Files

- `bin/up` — remove lines 54-56 (the `pkill -f tmux` block)

## Tests

No new tests needed — this is a removal of destructive code. Existing tests
in `tests/` do not cover `bin/up` (it requires `script::depends_on` and tmux).
