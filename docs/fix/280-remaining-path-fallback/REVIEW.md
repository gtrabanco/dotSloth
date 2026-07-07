# Review — fix/280-remaining-path-fallback

**Date:** 2026-07-05
**Branch:** fix/280-remaining-path-fallback
**Commits:** b501a8b (SPEC), 372f439 (implementation)
**Size:** XS

## Diff summary

6 mechanical replacements of `${SLOTH_PATH:-${DOTLY_PATH:-}}` → `${SLOTH_PATH:-}`
in `scripts/init/{enable,disable,status}` (lines 5 and 8 of each).

## Findings

### Correctness — PASS

- The replacements are correct. `bin/dot` exports `SLOTH_PATH` before
  dispatching context scripts (bin/dot:190), making the `DOTLY_PATH` fallback
  redundant in these files.
- The guard check on line 5 still functions: if `SLOTH_PATH` is empty, the
  script exits with code 1.
- Line 8 sources `_main.sh` using `${SLOTH_PATH:-}` — if `SLOTH_PATH` is set
  (guaranteed by `bin/dot` dispatch), the path resolves correctly.

### Scope — PASS

- Only the 3 in-scope files were modified.
- Out-of-scope files verified untouched: `_main.sh`, `init-sloth.sh`,
  `bin/dot`, `bin/sloth`, `restorer`, `installer`, `scripts/core/install`.

### Gate — PASS

- `bash scripts/self/static_analysis` — exit 0
- `bash scripts/self/lint` — exit 0
- `make test` — 60 ok, 0 not ok

### Security — n/a

No auth, secrets, or PII involved.

### Performance — n/a

Mechanical variable reference change, no performance impact.

### Fix-now findings

None.

## Verdict

MERGE-READY — no blockers, no fix-now findings.
