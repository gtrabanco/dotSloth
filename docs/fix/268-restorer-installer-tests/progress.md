## P1 — 2026-07-14
- Done: Write restorer tests (has_component, validate_dotfiles, create_rollback_point+rollback, backup_dotfiles_dir)
- Remains: P2
- Gotchas: none
- Files: tests/core/restorer.bats, docs/fix/268-restorer-installer-tests/SPEC.md
- Next: P2 — Write installer tests

## P2 — 2026-07-14
- Done: Write installer tests (create_dotfiles_dir)
- Remains: P3
- Gotchas: none
- Files: tests/core/installer.bats, docs/fix/268-restorer-installer-tests/SPEC.md
- Next: P3 — Hardening & PR

## P3 — 2026-07-20
- Done: Added validate_dotfiles no-commits test gate (bats --recursive tests/ — 177/177 pass) updated SPEC checkboxes and decisions created progress.md
- Remains: none
- Gotchas: shfmt/shellcheck not available in this environment; bats tests all pass
- Files: docs/fix/268-restorer-installer-tests/SPEC.md, tests/core/restorer.bats, docs/fix/268-restorer-installer-tests/progress.md
- Next: unit finished
