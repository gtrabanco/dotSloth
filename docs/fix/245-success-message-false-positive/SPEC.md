# Fix #245 — Success message always shown despite failures

## Problem

`bin/up` always shows `log::success '👌 All your packages have been
successfully updated'` at the end, even when `update_all_error` was called for
one or more package managers. The exit code is always 0.

## Root cause

The loop at line 50 calls `update_all_error` on failure but does not track
which managers failed or set a non-zero exit code. The success message at
line 55 runs unconditionally.

## Fix

Track failed package managers in an array. After the loop, if any failed,
show an error message listing them and exit 1. Otherwise show the success
message.

## Files

- `bin/up` — add `failed_managers` array, track failures, conditional exit

## Tests

No new tests — `bin/up` requires package managers and is not currently tested
in bats. The fix is a straightforward conditional.
