# Testing: 12-skill-lockfile

## Gate commands
- `bash scripts/self/static_analysis` — static analysis (shellcheck)
- `bash scripts/core/lint` — shfmt formatting check

## Per-phase testing
- P1: Gate only (no feature tests yet). Validate yaml.sh, wrappers, skills.sh via shellcheck + shfmt.
- P2: Gate + manual test with populated `$HOME/.agents/skills/` directory.
- P3: Gate + manual test with manually created `skill-lock.yaml` file.
- P4: Gate + full integration tests + `make test` for regression coverage.
