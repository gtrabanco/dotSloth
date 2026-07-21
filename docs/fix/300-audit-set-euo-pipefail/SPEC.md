# fix/300-audit-set-euo-pipefail

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Audit all standalone/executable scripts for the `set -euo pipefail` header and
add it where missing. The architecture doc (`docs/architecture/ARCHITECTURE.md:38`)
declares this header mandatory for all standalone scripts, but 5 scripts in
`scripts/package/` were never migrated. This fix closes the compliance gap before
a missing header causes a silent failure.

## Issue

`#300` — tracked issue. Required. The PR must close it.

## Branch

`fix/300-audit-set-euo-pipefail`

## Root cause

The architecture rule requiring `set -euo pipefail` in all standalone scripts was
added after the existing `scripts/package/` scripts were written. PR #299 clarified
the doc to say "mandatory in all standalone/executable scripts" and noted that
sourced library files intentionally omit it, but the 5 affected scripts were never
retroactively updated.

Evidence — scripts missing the header:

```bash
for f in scripts/package/add scripts/package/brew scripts/package/dump \
         scripts/package/import scripts/package/install; do
  head -5 "$f" | grep -q "set -euo pipefail" || echo "MISSING: $f"
done
```

All 5 scripts have `#!/usr/bin/env bash` shebangs, source `scripts/core/src/_main.sh`,
and are dispatched as child processes via `bin/dot` (line 190 of `bin/dot` — the
`FORCE_LEGACY_EXECUTION` / `_main.sh` source-path branch). Each runs in its own shell
instance, so `set -euo pipefail` from `bin/dot` does NOT propagate to them.

## Scope

### In scope

Add `set -euo pipefail` to the 5 standalone scripts missing it, immediately after
the shebang line and before any other code:

| Script | Current header | Change |
|--------|---------------|--------|
| `scripts/package/add` | `#!/usr/bin/env bash` | Insert `set -euo pipefail` after shebang |
| `scripts/package/brew` | `#!/usr/bin/env bash` | Insert `set -euo pipefail` after shebang |
| `scripts/package/dump` | `#!/usr/bin/env bash` | Insert `set -euo pipefail` after shebang |
| `scripts/package/import` | `#!/usr/bin/env bash` | Insert `set -euo pipefail` after shebang |
| `scripts/package/install` | `#!/usr/bin/env bash` | Insert `set -euo pipefail` after shebang |

### Out of scope

- **`scripts/core/version`** — intentionally uses `set -uo pipefail` + `set +e`
  for control flow (avoids crash when functions return false). This is a deliberate
  design, not a missing guard. See triage evidence from 2026-07-07.
- **`bin/up`** — uses `#!/usr/bin/env sloth` shebang, does NOT source `_main.sh`,
  and is dispatched by `bin/dot` in source mode (line 197 of `bin/dot`). It inherits
  `set -euo pipefail` from `bin/dot`'s shell. Adding it again would be redundant.
  If this assessment is wrong, file a separate issue.
- **`scripts/core/_main.sh`** — sourced library, correctly omits `set -euo pipefail`
  per the architecture doc.
- **`scripts/core/short_pwd`** — zsh script (`#!/usr/bin/env zsh`), not bash. The
  convention applies to bash scripts. If zsh needs its own `set -e` equivalent,
  file a separate issue.
- **Directory entries** (`scripts/core/src`, `scripts/package/src`, `scripts/symlinks/src`)
  — these are directories, not scripts.

## Impact

- **Modules/files touched:** `scripts/package/add`, `scripts/package/brew`,
  `scripts/package/dump`, `scripts/package/import`, `scripts/package/install`.
  All in the `scripts/package/` layer.
- **Blast radius:** Low. Adding `set -euo pipefail` changes error-handling
  semantics: any command failure, unset variable, or pipe failure will now exit
  the script immediately instead of continuing silently. If a script has existing
  logic that depends on ignoring errors (e.g. `false || true` patterns), adding
  the header could change behavior. The verification gate and manual testing
  catch this.
- **Detection lead time:** Immediate — the verification gate (`./scripts/core/lint &&
  ./scripts/core/static_analysis`) runs on every commit. Manual testing of each
  script's primary function confirms no runtime regression.

## Rules that must never be violated

- `set -euo pipefail` is mandatory in all standalone/executable scripts
  (`docs/architecture/ARCHITECTURE.md:38`).
- Sourced library files (`scripts/core/src/*.sh`) intentionally omit it — do not
  add it to them.
- All scripts must be POSIX-compatible bash (`CLAUDE.md` hard rules).
- Shell compatibility: no bashisms that break on macOS default bash (3.2) unless
  explicitly guarded (`CLAUDE.md` hard rules).
- Context scripts must source `_main.sh` first (`docs/architecture/ARCHITECTURE.md:31-33`).
- Gate before commit: the verification gate must be green (`CLAUDE.md` hard rules).

## Risks

**Operational risks:**
- None. No scheduled jobs, queues, caches, schemas, or external adapters are
  affected. This is a shell header change.

**Security risks:**
- None. No auth, secrets, PII, webhooks, or rate-limits are involved.

**Compliance touchpoints:**
- n/a — this fix enforces an existing project convention, not a regulatory rule.

**Migration / backwards-compat:**
- n/a — no schema, cache, namespace, or slug changes.

## Acceptance criteria

- [ ] `scripts/package/add` contains `set -euo pipefail` after the shebang
  (unit: `head -5 scripts/package/add | grep -q 'set -euo pipefail'`)
- [ ] `scripts/package/brew` contains `set -euo pipefail` after the shebang
  (unit: `head -5 scripts/package/brew | grep -q 'set -euo pipefail'`)
- [ ] `scripts/package/dump` contains `set -euo pipefail` after the shebang
  (unit: `head -5 scripts/package/dump | grep -q 'set -euo pipefail'`)
- [ ] `scripts/package/import` contains `set -euo pipefail` after the shebang
  (unit: `head -5 scripts/package/import | grep -q 'set -euo pipefail'`)
- [ ] `scripts/package/install` contains `set -euo pipefail` after the shebang
  (unit: `head -5 scripts/package/install | grep -q 'set -euo pipefail'`)
- [ ] Verification gate passes: `./scripts/core/lint && ./scripts/core/static_analysis`
  (architecture: shellcheck + shfmt)
- [ ] Each modified script's primary function works without error
  (manual: run `dot package <script> --help` for each)
- [ ] No existing standalone script is regressed (manual: run `dot package dump`,
  `dot package add`, `dot package install`, `dot package import`, `dot package brew`
  with representative inputs)

## Rollback

Single `git revert <commit-hash>` — no data-side cleanup needed. Scripts revert to
their previous state. Nothing is preserved or lost since no data was modified.

## Effort

**XS** — 1 commit, ~30 minutes. Five one-line insertions plus gate verification and
manual testing.

## Phases

### P1 — Add `set -euo pipefail` to 5 scripts

- [ ] Add `set -euo pipefail` after the shebang in `scripts/package/add`
- [ ] Add `set -euo pipefail` after the shebang in `scripts/package/brew`
- [ ] Add `set -euo pipefail` after the shebang in `scripts/package/dump`
- [ ] Add `set -euo pipefail` after the shebang in `scripts/package/import`
- [ ] Add `set -euo pipefail` after the shebang in `scripts/package/install`
- [ ] Run verification gate: `./scripts/core/lint && ./scripts/core/static_analysis`
- [ ] Run each modified script's `--help` to confirm no runtime breakage

**Phase-lint:**
- [ ] All tasks independently checkable without judgement
- [ ] Zero open design decisions
- [ ] One layer/concern (shell header compliance)
- [ ] Gate runnable locally (verification gate)
- [ ] No cross-file dependencies beyond the header pattern
- [ ] No external service calls
- [ ] No data migration
- [ ] Scope matches the issue (5 scripts, 1 rule)

### P2 — Hardening & PR

- [ ] Verify branch is `fix/300-audit-set-euo-pipefail`
- [ ] Verify all acceptance criteria pass
- [ ] Commit: `fix(scripts): add set -euo pipefail to 5 package scripts`
- [ ] Push branch and open PR with `Closes #300`
- [ ] PR description references the architecture doc section (`docs/architecture/ARCHITECTURE.md:38`)

### Spec-lint

- [ ] All template sections filled
- [ ] All claims cite a file path or doc section
- [ ] Scope didn't creep vs. issue body
- [ ] Out-of-scope items each have a destination
- [ ] Acceptance criteria are independently-verifiable checkboxes
- [ ] `## Phases` has ≥ 2 phases and ends with the literal `Hardening & PR` tasks
- [ ] Every implementation phase passes all 8 phase-lint boxes
- [ ] All English

## Observability

- Log: no new log lines needed — this is a mechanical compliance fix.
- Metric: the verification gate (`lint && static_analysis`) confirms shellcheck
  accepts the modified scripts. A green gate is the health signal.
- Alert: n/a.

## Cross-issue notes

- **PR #299** (closed) — updated the architecture doc to clarify `set -euo pipefail`
  is mandatory for standalone scripts and optional for sourced libs. This issue
  closes the gap that PR #299 identified but didn't fix. No conflict; PR #299 is
  already merged.
- **Issue #224** (open) — documentation improvements needed. Unrelated to this fix.
  Do not absorb.
- **Issue #273** (open) — grep-based test regression guards. Unrelated to this fix.
  Do not absorb.

## Decisions made during drafting

- **`bin/up` excluded:** Dispatched in source mode by `bin/dot` (line 197), inherits
  `set -euo pipefail` from the parent shell. If evidence shows otherwise (e.g. `bin/up`
  is sometimes invoked directly without `bin/dot`), this assessment should be revisited.
- **`scripts/core/version` excluded:** Intentional `set -uo pipefail` + `set +e`
  design per triage evidence from 2026-07-07. Not a compliance gap.
- **`scripts/core/short_pwd` excluded:** Zsh script, not bash. The convention is
  bash-specific. If zsh needs `set -e`, file separately.
- **No new tests added:** The fix is a mechanical header insertion. The verification
  gate (shellcheck + shfmt) and manual script invocation are sufficient. Adding unit
  tests for "does this file contain a string" would be overengineering.
