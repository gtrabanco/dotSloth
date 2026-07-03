# Active fixes

Index of in-progress and pending fixes. Merged fixes are removed from this table —
history lives in git log + closed issues.

## Status legend

- `pending` — SPEC drafted, branch not yet open
- `in-progress` — branch open, work ongoing
- `done` — built, PR open, awaiting merge (merge state lives in the forge — same
  meaning as the roadmap's `done`); remove the row only **after** the PR merges

## Active

| Folder | Topic | Status | Depends on | Issue |
|--------|-------|--------|------------|-------|
| | Auto-updater no funciona | pending | — | [#233](https://github.com/gtrabanco/dotSloth/issues/233) |
| | Restorer no funciona | pending | — | [#234](https://github.com/gtrabanco/dotSloth/issues/234) |
| | Comando up falla al parsear | pending | — | [#235](https://github.com/gtrabanco/dotSloth/issues/235) |
| | pip::update_apps() typo doble install | done | — | [#243](https://github.com/gtrabanco/dotSloth/issues/243) |
| | dnf check-update aborta con set -e | pending | — | [#244](https://github.com/gtrabanco/dotSloth/issues/244) |
| | Mensaje exit siempre se muestra | pending | — | [#245](https://github.com/gtrabanco/dotSloth/issues/245) |
| | script::depends_on cuelga no-interactivo | pending | — | [#246](https://github.com/gtrabanco/dotSloth/issues/246) |
| | pkill tmux destruye todas sesiones | pending | — | [#247](https://github.com/gtrabanco/dotSloth/issues/247) |
| | mas::update_all() lento y puede colgar | pending | — | [#248](https://github.com/gtrabanco/dotSloth/issues/248) |

## Conventions

- One folder per fix: `docs/fix/<issue-number>-<topic>/SPEC.md`.
- Every fix has a tracked issue; the PR closes it.
- Remove the row when the PR merges.
