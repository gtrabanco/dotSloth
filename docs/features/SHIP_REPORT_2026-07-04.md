# Ship Report — dotSloth bugs + tech-debt (fullauto)

**Run mode:** `--fullauto` (auto-merge with non-negotiable safety floors)
**Founded:** 2026-07-03
**Completed:** 2026-07-04
**Iterations used:** 16 / 28 cap
**Stop reason:** All units merged + issue sweep complete (no fix-now issues found)

## Run summary

| Metric | Value |
|--------|-------|
| Mode | `--fullauto` |
| Units in scope | 7 (6 bugs + 1 tech-debt) |
| Units merged | 7/7 ✅ |
| Units parked | 0 |
| Units not started | 0 |
| PRs created | 7 (#257, #258, #259, #260, #261, #262, #263) |
| PRs merged by autopilot | 7 (all `--merge`, not squash) |
| PRs merged by human | 0 |
| Iterations used | 16 / 28 |
| Red gate retries | 0 |
| Review-fix cycles | 0 |
| Audit-fix cycles | 1 (#255 CI compat fix) |

## Per-unit outcomes

| Unit | Issue | Size | Bugs fixed | PR | SHA | Merged by |
|------|-------|------|------------|-----|-----|-----------|
| u1 | #247 — pkill tmux | XS | 1 | [#257](https://github.com/gtrabanco/dotSloth/pull/257) | 642dab4 | autopilot |
| u2 | #246 — depends-on hangs | XS | 1 | [#258](https://github.com/gtrabanco/dotSloth/pull/258) | ed07a30 | autopilot |
| u3 | #245 — Success false positive | S | 1 | [#259](https://github.com/gtrabanco/dotSloth/pull/259) | 13666eb | autopilot |
| u4 | #233 — Auto-updater broken | S | 3 | [#260](https://github.com/gtrabanco/dotSloth/pull/260) | 4a72765 | autopilot |
| u5 | #234 — Restorer broken | M | 4 | [#261](https://github.com/gtrabanco/dotSloth/pull/261) | 2df0d57 | autopilot |
| u6 | #235 — up parse updates | M | 8 | [#262](https://github.com/gtrabanco/dotSloth/pull/262) | adb9f79 | autopilot |
| u7 | #255 — DOTLY_PATH/SLOTH_PATH refactor | M | 53 replacements + 1 CI compat fix | [#263](https://github.com/gtrabanco/dotSloth/pull/263) | ca6ade5 | autopilot |

**Total bugs/replacements fixed:** 71

### Notable: Unit 7 (#255) CI compat fix

The subagent completed the 53-occurrence refactor correctly, but CI failed because `_main.sh` — the first file loaded by the framework — used `${SLOTH_PATH:-}` without a `DOTLY_PATH` fallback. CI sets only `DOTLY_PATH` (not `SLOTH_PATH`), and the compatibility layer in `init-sloth.sh` doesn't run in CI. The conductor fixed this by adding early resolution of `SLOTH_PATH` from `DOTLY_PATH` at the top of `_main.sh`, before any library loads. Verified with `env -u SLOTH_PATH DOTLY_PATH=...` (simulating CI): all gates green.

## Issue sweep

### Inventory

14 open issues + 1 documented residue from review reports.

### Triage verdicts

| Issue | Title | Verdict | Rationale |
|-------|-------|---------|-----------|
| #236 | Migrar docpars a Rust | promote-to-feature | Already in ROADMAP as feature 01 |
| #237 | Migrar `dot` a Rust | promote-to-feature | Already in ROADMAP as feature 02 |
| #238 | Migrar `up` a Rust | promote-to-feature | Already in ROADMAP as feature 03 |
| #239 | Sync upstream | promote-to-feature | Already in ROADMAP as feature 04 |
| #240 | Sistema de testing | promote-to-feature | Already in ROADMAP as feature 05 (in-progress) |
| #241 | PM timeouts | promote-to-feature | Already in ROADMAP as feature 06 |
| #242 | Restorer v2 | promote-to-feature | Already in ROADMAP as feature 07 |
| #224 | Documentation improvements | postpone | Doc enhancement, not blocking |
| #223 | Discussion: Migrate dot | postpone | Discussion, superseded by #236/#237 |
| #222 | Discussion: Add gum | postpone | Discussion, exploratory |
| #218 | Discussion: Init scripts | postpone | Discussion, exploratory |
| #217 | [BUG] Documentation in code | postpone | Doc bug, low impact |
| #209 | Help: Create tutorial | postpone | Community help request |
| — | No tests for sloth_update.sh | wontfix | Project limitation, documented in review #233 F-2 |

### Fix-now issues shipped

None. All open issues are features, discussions, or doc enhancements — none are fix-now.

## New feature proposals

No new feature proposals discovered during this run. The existing roadmap (features 01-07) covers the migration path validated by this run.

## Residual risks

1. **No dedicated tests for `sloth_update.sh`** — the auto-updater (fix #233) was fixed without adding new tests. The existing test suite covers `dnf::outdated_app` (test 44) but not the update flow itself. Low risk for a throwaway profile.
2. **`_main.sh` CI compat fix** — the early resolution of `SLOTH_PATH` from `DOTLY_PATH` is a runtime fix, not a test-covered path. If someone removes those two lines, CI will break again. Consider adding a test that verifies `_main.sh` loads with only `DOTLY_PATH` set.
3. **`restorer` not fully tested** — the 4 bugs fixed in #234 were structural (undefined function, inverted guard, missing load). No integration tests were added for the restorer flow.

## Manual-verification checklist

- [ ] Verify `dot up` works on a real system with multiple package managers
- [ ] Verify `dot update` (auto-updater) works end-to-end
- [ ] Verify `restorer` restores dotfiles from both git and iCloud sources
- [ ] Verify `DOTLY_PATH` backward compatibility: scripts that set only `DOTLY_PATH` (not `SLOTH_PATH`) still work
- [ ] Review the 53 `${SLOTH_PATH:-}` replacements for any edge case where `DOTLY_PATH` was intentionally the primary variable

## Going forward

### Product-audit cadence

This run shipped 7 PRs (6 bug fixes + 1 tech-debt refactor). A `product-audit` is recommended now to validate the overall health of the codebase after these changes, then every ~5 features or pre-release.

### Suggested command sequence

```
→ Next: /product-audit  · accepted proposals → /plan-feature --next  · product-audit due now
```

---

*this report recommends; the human decides.*
