# Testing: 04-upstream-sync

## Gate commands
- `bash scripts/self/static_analysis` — static analysis
- `bash scripts/core/lint` — shellcheck lint
- `make test` — full test suite (60 tests)

## Per-phase testing
- P1: No code changes; audit only
- P2: Run gate after each module sync
- P3: Run gate after adding utility scripts
- P4: Run gate after each file sync
