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
