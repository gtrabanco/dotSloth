# Roadmap

The single source of truth for feature **numbering, ordering, and dependencies**.
Every feature folder under `docs/features/<NN>-<slug>/` must have a row here, and
every row must have a corresponding folder.

## Features

| # | Slug | Status | Depends on | Description | Issue |
|---|------|--------|------------|-------------|-------|
| 01 | `rust-tooling` | planned | — | Migrar docpars/docopts a tooling propio en Rust con clap-rs · [#204](https://github.com/gtrabanco/dotSloth/pull/204) | [#203](https://github.com/gtrabanco/dotSloth/issues/203) |
| 02 | `rust-dot-cli` | planned | 01 | Migrar comando `dot` a Rust con clap-rs para parsing robusto · [#205](https://github.com/gtrabanco/dotSloth/pull/205) | [#206](https://github.com/gtrabanco/dotSloth/issues/206) |
| 03 | `rust-up-cli` | planned | 01 | Migrar comando `up` a Rust con manejo robusto, timeouts, feedback · [#207](https://github.com/gtrabanco/dotSloth/pull/207) | [#208](https://github.com/gtrabanco/dotSloth/issues/208) |
| 04 | `upstream-sync` | done | — | Sincronizar mejoras upstream de CodelyTV/dotly · [#215](https://github.com/gtrabanco/dotSloth/pull/215) | [#214](https://github.com/gtrabanco/dotSloth/issues/214) |
| 05 | `testing-framework` | done | — | Implementar sistema de testing completo con bats-core · [#251](https://github.com/gtrabanco/dotSloth/pull/251) | [#250](https://github.com/gtrabanco/dotSloth/issues/250) |
| 06 | `pm-timeouts` | done | — | Mejorar sistema de package managers con timeouts configurables · [#294](https://github.com/gtrabanco/dotSloth/pull/294) | [#292](https://github.com/gtrabanco/dotSloth/issues/292) |
| 07 | `restorer-v2` | done | — | Mejorar restorer con validación, rollback, restauración parcial · [#295](https://github.com/gtrabanco/dotSloth/pull/295) | [#296](https://github.com/gtrabanco/dotSloth/issues/296) |
| 08 | `test-coverage-expansion` | done | — | Add tests for sloth_update.sh auto-updater flow + critical path coverage · [#293](https://github.com/gtrabanco/dotSloth/pull/293) | [#291](https://github.com/gtrabanco/dotSloth/issues/291) |
| 09 | `mock-harness` | done | — | Mock harness for external commands (unblocks #268, #273) · [#303](https://github.com/gtrabanco/dotSloth/pull/303) | [#302](https://github.com/gtrabanco/dotSloth/issues/302) |
| 10 | `core-library-tests` | done | 09 | Deep functional tests for core libraries (array, str, json, git) · [#310](https://github.com/gtrabanco/dotSloth/pull/310) | [#301](https://github.com/gtrabanco/dotSloth/issues/301) |
| 11 | `local-ci-pre-commit` | done | — | Add pre-commit hooks (format → lint → test), local Makefile targets, CI format job, and merge gate constraint · [#327](https://github.com/gtrabanco/dotSloth/pull/327) | [#328](https://github.com/gtrabanco/dotSloth/issues/328) |
| 12 | `skill-lockfile` | done | — | Package dump/import for agent skills (`bunx`/`npx` skills) with YAML lockfile and skills.sh integration · [#332](https://github.com/gtrabanco/dotSloth/pull/332) · [#330](https://github.com/gtrabanco/dotSloth/issues/330) | [#330](https://github.com/gtrabanco/dotSloth/issues/330) |

## Status legend

- `idea` — a roadmap row exists, but product design has not been completed. Next action: `/design-feature <slug>`.
- `defined` — `SPEC.md` exists with its product half complete and `Design status: designed`. Next action: `/plan-feature <slug>`.
- `planned` — in the roadmap, not started
- `in-progress` — branch open, phases executing
- `done` — built and its PR open (the last step opened the PR); **merge state lives
  in the forge**, not the status — a `done` row may still be awaiting a human merge

## Conventions

- Numbers are assigned in order and never reused.
- A feature that depends on another cannot start until its dependency is **merged**
  (not merely `done` — a `done` dep with an open PR isn't on `main` yet).
- A unit is executable only when `planned` or above. Sub-`planned` work returns to design (`idea`) or planning (`defined`) before execution.
- Keep this table consistent with the feature folders (the `audit-docs` skill
  checks for drift).
- Each feature should have a corresponding GitHub issue referenced in the Issue column.
- When a feature PR is merged, close the referenced issue.