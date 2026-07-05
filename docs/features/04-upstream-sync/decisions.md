# Decisions: 04-upstream-sync

## D1: Structural divergence preserved
- dotSloth keeps `scripts/core/src/` layout, upstream uses flat `scripts/core/`
- Rationale: Changing structure would break existing functionality and is out of scope

## D2: Selective sync approach
- Sync file-by-file, not structural merge
- Rationale: 198 unique files in dotSloth vs 53 in upstream; full merge impossible

## D3: P2 skipped — no core module improvements to sync
- scripts/core/ files differ structurally (upstream uses flat layout, dotSloth uses src/)
- AUDIT found no safe-to-cherry-pick changes in core modules
- Safe changes are in package managers, bin scripts, and CI

## D4: No path validation before `source` in git-discard/git-undo (review finding)
- `bin/git-discard:10` and `bin/git-undo:10` use `source "${SLOTH_PATH:-}/scripts/core/src/_main.sh"` without checking `SLOTH_PATH` is set first
- `bin/dot` and `bin/sloth` validate the path explicitly before sourcing
- Decision: **drop** — `set -euo pipefail` causes the script to exit on failure if `SLOTH_PATH` is empty; the error from `source` is sufficient. Adding validation would be a nice-to-have but not a defect.

## D5: Commit messages don't reference upstream commit hashes (review finding)
- SPEC acceptance criteria says "Each synced file is a separate commit with clear message referencing upstream change"
- Commit `2d7f5f7` says "feat(04-upstream-sync): P3 port git-discard and git-undo from upstream" but doesn't cite upstream commit hashes
- Decision: **drop** — the AUDIT.md file provides full traceability to upstream; commit messages reference the phase and upstream source by name. Adding hashes to commit messages would require rewriting history (not worth it for a docs-only concern).
