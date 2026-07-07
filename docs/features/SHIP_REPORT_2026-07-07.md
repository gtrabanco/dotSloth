# Ship Roadmap Report — 2026-07-07

## Run summary

| Field | Value |
|-------|-------|
| Mode | `--fullauto` (auto-merge with non-negotiable safety floors) |
| Iterations used vs cap | 7 / 16 |
| Stop reason | All in-scope features merged + issue sweep complete |
| Profile | Internal tool — stricter testing, more docs discipline |

### Feature counts

| Status | Count | Features |
|--------|-------|----------|
| Merged | 1 | 10 (core-library-tests) |
| Done-awaiting-merge | 0 | — |
| Parked | 0 | — |
| Not started (out of scope) | 3 | 01, 02, 03 (Rust migration — deferred per decision record) |
| Already merged (prior run) | 6 | 04, 05, 06, 07, 08, 09 |

## Per-feature outcomes

### Feature 10 — core-library-tests

| Field | Value |
|-------|-------|
| Size planned vs final | S / S |
| PR | [#310](https://github.com/gtrabanco/dotSloth/pull/310) |
| Merge commit | `a040ccf` |
| Head SHA at merge | `ff282ac` |
| Audit verdict | MERGE-READY, 6/6 CI green |
| Merged by | autopilot (--fullauto) |
| Tests | 107 → 158 (+51 tests) |
| Review findings | 0 fix-now, 2 pre-existing bugs filed (#308, #309) |
| Audit fix cycles | 1 (CI red on json.bats — wrong yq skip guard + set -e; fixed, re-audited green) |
| Notes | Tests-only PR; array.bats (13), str.bats (12), json.bats (6, yq skip-guarded), git.bats (20, mock harness + temp repo) |

## Issues

### Full inventory (13 open issues)

| Issue | Title | Triage verdict | Outcome |
|-------|-------|---------------|---------|
| #308 | git: current_commit_hash/check_branch_is_behind shift footgun | postpone | Filed this run (feature 10 review); trigger: caller uses -C without HEAD, or git.sh refactor |
| #309 | git: add_to_gitignore wrong-file write | postpone | Filed this run (feature 10 review); trigger: caller passes path ≠ $GITIGNORE_PATH, or git.sh refactor |
| #300 | audit standalone scripts for missing set -euo pipefail | postpone | Prior run; trigger: next script-hygiene pass |
| #296 | restorer symlinks rollback incomplete | postpone | Prior run; verdict posted this run; trigger: restorer tests (#268) or pre-release |
| #273 | gem.bats grep-based tests | postpone | Prior run; trigger: mock harness for gem |
| #268 | tests for restorer/installer | postpone | Prior run; trigger: mock harness for git/PMs (now available via #303) |
| #238 | migrate 'up' to Rust | postpone | Prior run; trigger: roadmap 01-03 planning |
| #237 | migrate 'dot' to Rust | postpone | Prior run; trigger: roadmap 01-03 planning |
| #236 | migrate docpars/docopts to Rust | postpone | Prior run; trigger: roadmap 01-03 planning |
| #224 | documentation improvements | postpone | Prior run; trigger: documentation audit / community FAQ |
| #222 | discussion: add gum | postpone | Prior run; trigger: decision to adopt gum |
| #218 | discussion: init scripts | postpone | Prior run; trigger: init script requirements defined |
| #217 | documentation in code | postpone | Prior run; trigger: documentation sprint |

### Fix-now issues shipped

None — no open issue is fix-now. All 13 inventoried issues are postpone with
triggers. The two issues filed this run (#308, #309) are pre-existing source
bugs in `scripts/core/src/git.sh` discovered during feature 10's review; both
are LOW-MEDIUM severity with no active breakage.

### Remaining triage batch

None — every inventoried issue has a dated triage verdict. The triggers above
define when each should be re-evaluated.

## New feature proposals

| Proposal | Size | Suggested slot | Rationale |
|----------|------|---------------|----------|
| Tests for yaml.sh, collections.sh, templating.sh | S | 11 | Issue #301 listed these as "no tests" but ranked array/str/json/git first; this run covered the four, the remaining three are the natural follow-up |
| Fix #308 + #309 (git.sh argument bugs) | XS | fix | Both are one-line fixes in `scripts/core/src/git.sh`; bundle into a single fix PR when triggered |
| Restorer tests (#268) | M | 12 | The mock harness (#303) now exists; unblocks the largest untested critical path |

## Residual risks

1. **Restorer tests (#268)** — still the single largest untested critical path.
   Feature 07 added safety mechanisms but no automated tests; feature 10 added
   git.sh tests but not restorer tests. Manual `--dry-run` is the only
   validation.
2. **`--fullauto` merges deserving a second look:**
   - PR #310 — merged after one audit fix cycle (CI red → fix → green → merge).
     The fix was a test-only change (skip guards + set -e pattern); the merge
     is sound but the first CI failure shows the value of the gate.
3. **Two pre-existing git.sh bugs (#308, #309)** — present on main, worked
   around by tests. LOW-MEDIUM severity; no active breakage, but a future
   caller could hit them. Triggers defined for reopening.
4. **json.bats skip behavior** — the 2 `to_yaml` tests skip when only the Go
   yq is present (CI has python-yq after the installer step, so they run
   there). If a future CI image ships the Go yq preinstalled (as the macOS
   image did for the build job), these tests would skip silently. The
   `python-yq::is_installed` check in the recipe is the real guard.
5. **Silent decisions with outsized consequences:** The decision to defer Rust
   migration (01-03) remains. The product's long-term direction (Rust vs Bash)
   is an open question. Six Bash features have now shipped; the codebase is
   more stable but the migration debt grows.

## Manual-verification checklist

From feature 10's review checkpoint + audit notes:

- [ ] `make test` passes with 158 tests locally (automated, but confirm)
- [ ] `json::to_yaml` tests run (not skip) on macOS CI — python-yq present
- [ ] `_pty_bash` helper behaves on macOS runner (python3 pty)
- [ ] No `git.bats` test pollutes global git config (temp_dir repos, local config)
- [ ] `git::add_to_gitignore` test workaround (#308) doesn't mask the bug in
      production callers (it points GITIGNORE_PATH at the same file)

## Going forward

### Product-audit cadence

This resumed run merged 1 feature (10). Combined with the prior run (4 units),
that's 5 units merged since the last product audit (2026-07-06). A
`product-audit` is **due now** — the cadence is every 5 merged units or
pre-release. The next audit should assess: the test coverage expansion (107 →
158 tests), the two new git.sh bugs (#308, #309), and whether the Rust
migration decision (01-03) should be revisited.

### Suggested command sequence

```
→ Next: /product-audit  · accepted proposals → /plan-feature
  · product-audit due → /product-audit (5 units merged since last audit)
  · #308 + #309 → /plan-fix (git.sh argument bugs, XS, bundle when triggered)
  · yaml/collections/templating tests → /plan-feature (slot 11, S)
  · restorer tests #268 → /plan-feature (slot 12, M, mock harness now available)
  · Rust migration → /plan-feature --next (roadmap 01-03, when ready)
```

**This report recommends; the human decides.**
