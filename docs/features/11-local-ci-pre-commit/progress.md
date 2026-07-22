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
