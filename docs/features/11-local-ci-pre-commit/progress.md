## P1 — 2026-07-22
- Done: Created `.pre-commit-config.yaml` with 3 local hooks (shfmt format, shfmt lint, bats test)
- Remains: none
- Gotchas: none
- Files: `.pre-commit-config.yaml`
- Next: P2 — Add Makefile targets and scripts/self/pre-commit wrapper

## P2 — 2026-07-22
- Done: Added `format`, `lint`, `pre-commit-pre-push` targets to Makefile; created `scripts/self/pre-commit` wrapper
- Remains: none
- Gotchas: Gate scripts require `SLOTH_PATH` and `DOTFILES_PATH` to be set; worktree needs explicit env vars
- Files: `Makefile`, `scripts/self/pre-commit`
- Next: P3 — Update CI (`.github/workflows/ci.yml`) — add format job on macOS + Ubuntu matrix

## P3 — 2026-07-22
- Done: Added `format` CI job to `.github/workflows/ci.yml` running `shfmt -d` on macOS + Ubuntu matrix
- Remains: none
- Gotchas: Format job installs shfmt via Go (same pattern as lint job); uses `-d` (diff) mode for check, not `-w` (write)
- Files: `.github/workflows/ci.yml`
- Next: P4 — Update CLAUDE.md with merge gate constraint

## P4 — 2026-07-23
- Done: Added merge gate section to CLAUDE.md (restored from fold commits that landed on main)
- Remains: none
- Gotchas: Fold commits for F8/F9 (merge gate) went to `main` instead of the branch; had to re-add
- Files: `CLAUDE.md`
- Next: P5 — Hardening & PR

## P5 — 2026-07-23
- Done: `lint` + `static_analysis` pass (exit 0); pre-commit hooks verified (format/lint fail on pre-existing log.sh issue, test passes); ROADMAP row restored and marked `done`; PR [#327](https://github.com/gtrabanco/dotSloth/pull/327) opened
- Remains: none
- Gotchas: `make` not available in this CI-less environment; `shfmt` had to be installed via `pip install shfmt-py`; pre-existing shfmt parse error in `scripts/core/src/log.sh:62` (`${#1:-}`) causes pre-commit hooks to fail on format/lint — not introduced by this PR
- Files: `CLAUDE.md`, `docs/features/ROADMAP.md`
- Next: Hand off to review-change
