# Review Findings — fix/268-restorer-installer-tests

**PR:** [#324](https://github.com/gtrabanco/dotSloth/pull/324)
**Audit date:** 2026-07-20
**Updated:** 2026-07-20 (blockers fixed on branch)
**Head SHA:** `f9422d2` (post-fold; CI green 6/6)
**Verdict:** MERGE-READY (all blockers folded)

---

## Blockers (fixed on-branch except env-limited CI)

| id | file:line | axis | severity | class | route | folded |
|----|-----------|------|----------|-------|-------|--------|
| B1 | `docs/fix/README.md:18` | Mergeability | high | fix-now | rebase + conflict resolve + commit | yes |
| B2 | `SPEC.md:67-71` | Acceptance criteria | high | fix-now | ticked checkboxes + commit | yes |
| B3 | `statusCheckRollup` | Verification gate / CI | high | fix-now | push; CI must run green (tools unavailable in audit env) | yes |
| B4 | restorer/installer.bats (F2-F6,F9) | Review axes | high | fix-now | folded via direct fixes (stubs, temp_dir scoping, colors, else test) + commit | yes |

## Deferred (from prior adversarial review — out of scope, tracked)

| id | file:line | axis | severity | class | route | folded |
|----|-----------|------|----------|-------|-------|--------|
| F7 | `restorer:133` | Review axes | medium | postpone | production bug, out of scope for test-only PR | no |
| F8 | `restorer:174` | Review axes | medium | postpone | production bug, out of scope for test-only PR | no |
| F10 | `installer:23,27` | Review axes | low | postpone | production design pattern, out of scope | no |

## Fixes applied (this pass)

- B1: `git rebase origin/main`; resolved docs/fix/README.md (both index rows); clean rebase; now independently mergeable.
- B2: Ticked all 5 AC checkboxes in SPEC.md.
- B4/F2: Replaced extraction of _w/_a/_e/_s with no-op stubs in both .bats setup() — reduces eval surface while keeping calls safe.
- B4/F3: Scoped `ls ... *.back` globs to a test-owned `$(temp_dir)` parent dir (unique per test, cleaned by rm -rf parent).
- B4/F4+F5: Replaced `"/tmp/...-$$"` with `$(temp_dir)/newdir` (non-existing path); removed obsolete cleanup pattern; standardized on temp_dir().
- B4/F6: Added explicit `red/green/purple/normal` assignments in setup() before any extracted calls.
- B4/F9: Enhanced else-branch test for backup_dotfiles_dir (non-exist case) with explicit "no *.back created" assertion.
- All 177 bats tests still pass; lint (with dummies) reports clean on changed files.
- B3: PR pushed (f9422d2); CI re-ran green (6/6 SUCCESS — Lint, Static analysis, Tests (ubuntu/macos), Build (ubuntu/macos)).

Note: full `static_analysis` requires `shellcheck` binary (unavailable in this env, as documented); will be enforced by CI on push.
