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
| `319-is-valid-commit-C-option` | `is_valid_commit` consumes `-C` as commit (twin of #308/#314) | done | — | #319 |
| `315-add-to-gitignore-regex` | `add_to_gitignore` regex dedup false match on glob metacharacters | done | — | #315 |

## Conventions

- One folder per fix: `docs/fix/<issue-number>-<topic>/SPEC.md`.
- Every fix has a tracked issue; the PR closes it.
- Remove the row when the PR merges.
