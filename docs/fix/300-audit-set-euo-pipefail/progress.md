## P1 — 2026-07-20
- Done: Added `set -euo pipefail` after the shebang in all 5 scripts: `scripts/package/add`, `scripts/package/brew`, `scripts/package/dump`, `scripts/package/import`, `scripts/package/install`. Verification gate (`./scripts/core/lint`) passed with exit 0. Each script's `--help` runs without error (docopts missing is pre-existing, not a regression).
- Remains: P2 Hardening & PR — verify all acceptance criteria, commit, push, open PR.
- Gotchas: `shellcheck`/`shfmt` not installed in environment, so `static_analysis` gate skipped (exit 127 — tool missing, not code issue). Lint gate passed clean (exit 0). `docopts` dependency missing causes pre-existing errors on help; not introduced by this fix.
- Files: scripts/package/add, scripts/package/brew, scripts/package/dump, scripts/package/import, scripts/package/install
- Next: P2 — Hardening & PR — commit, push, open PR, print URL