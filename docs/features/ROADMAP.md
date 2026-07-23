# Roadmap

The single source of truth for feature **numbering, ordering, and dependencies**.
Every feature folder under `docs/features/<NN>-<slug>/` must have a row here, and
every row must have a folder (or be explicitly marked "scheduled").

## Features

| NN | Slug | Status | Depends on | Summary | Issue |
|----|------|--------|------------|---------|-------|
| 01 | `rust-tooling` | planned | — | Migrar docpars/docopts a tooling propio en Rust con clap-rs | [#236](https://github.com/gtrabanco/dotSloth/issues/236) |
| 02 | `rust-dot-cli` | planned | 01 | Migrar comando `dot` a Rust con clap-rs para parsing robusto | [#237](https://github.com/gtrabanco/dotSloth/issues/237) |
| 03 | `rust-up-cli` | planned | 01 | Migrar comando `up` a Rust con manejo robusto, timeouts, feedback | [#238](https://github.com/gtrabanco/dotSloth/issues/238) |
| 04 | `upstream-sync` | done | — | Sincronizar mejoras upstream de CodelyTV/dotly | [#239](https://github.com/gtrabanco/dotSloth/issues/239) · [#283](https://github.com/gtrabanco/dotSloth/pull/283) |
| 05 | `testing-framework` | done | — | Implementar sistema de testing completo con bats-core · [#251](https://github.com/gtrabanco/dotSloth/pull/251) | [#240](https://github.com/gtrabanco/dotSloth/issues/240) |
| 06 | `pm-timeouts` | done | — | Mejorar sistema de package managers con timeouts configurables · [#294](https://github.com/gtrabanco/dotSloth/pull/294) | [#241](https://github.com/gtrabanco/dotSloth/issues/241) |
| 07 | `restorer-v2` | done | — | Mejorar restorer con validación, rollback, restauración parcial · [#295](https://github.com/gtrabanco/dotSloth/pull/295) | [#242](https://github.com/gtrabanco/dotSloth/issues/242) |
| 08 | `test-coverage-expansion` | done | — | Add tests for sloth_update.sh auto-updater flow + critical path coverage · [#293](https://github.com/gtrabanco/dotSloth/pull/293) | [#267](https://github.com/gtrabanco/dotSloth/issues/267) |
| 09 | `mock-harness` | done | — | Mock harness for external commands (unblocks #268, #273) · [#303](https://github.com/gtrabanco/dotSloth/pull/303) | [#302](https://github.com/gtrabanco/dotSloth/issues/302) |
| 10 | `core-library-tests` | done | 09 | Deep functional tests for core libraries (array, str, json, git) · [#310](https://github.com/gtrabanco/dotSloth/pull/310) | [#301](https://github.com/gtrabanco/dotSloth/issues/301) |
| 11 | `local-ci-pre-commit` | done | — | Add pre-commit hooks (format → lint → test), local Makefile targets, CI format job, and merge gate constraint · [#327](https://github.com/gtrabanco/dotSloth/pull/327) | [#328](https://github.com/gtrabanco/dotSloth/issues/328) |

## Status legend

- `planned` — in the roadmap, not started
- `in-progress` — branch open, phases executing
- `done` — built and its PR open (the last step opened the PR); **merge state lives
  in the forge**, not the status — a `done` row may still be awaiting a human merge

## Conventions

- Numbers are assigned in order and never reused.
- A feature that depends on another cannot start until its dependency is **merged**
  (not merely `done` — a `done` dep with an open PR isn't on `main` yet).
- Keep this table consistent with the feature folders (the `audit-docs` skill
  checks for drift).
- Each feature should have a corresponding GitHub issue referenced in the Issue column.
- When a feature PR is merged, close the referenced issue.
