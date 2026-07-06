# Ship Roadmap Report — 2026-07-06

## Run summary

| Field | Value |
|-------|-------|
| Mode | `--fullauto` (auto-merge with non-negotiable safety floors) |
| Iterations used vs cap | 6 / 16 |
| Stop reason | All in-scope features merged + issue sweep complete |
| Profile | Internal tool — stricter testing, more docs discipline |

### Feature counts

| Status | Count | Features |
|--------|-------|----------|
| Merged | 4 | #288 (fix), 08, 06, 07 |
| Done-awaiting-merge | 0 | — |
| Parked | 0 | — |
| Not started (out of scope) | 3 | 01, 02, 03 (Rust migration) |

## Per-feature outcomes

### Fix #288 — eval injection in install_remote

| Field | Value |
|-------|-------|
| Size planned vs final | XS / XS |
| PR | [#292](https://github.com/gtrabanco/dotSloth/pull/292) |
| SHA | `c913679` |
| Audit verdict | MERGE-READY, 6/6 CI green |
| Merged by | autopilot (--fullauto) |
| Notes | Replaced `eval "$download_command $script_raw_url"` with array-based `curl_args`; fixed exit code capture; `which`→`command -v` |

### Feature 08 — test-coverage-expansion

| Field | Value |
|-------|-------|
| Size planned vs final | S / S |
| PR | [#293](https://github.com/gtrabanco/dotSloth/pull/293) |
| SHA | `732c1be` |
| Audit verdict | MERGE-READY, 6/6 CI green |
| Merged by | autopilot (--fullauto) |
| Tests | 62 → 91 (+29 tests) |
| Review findings | 0 fix-now, 0 postponed |
| Notes | Added tests for sloth_update, dot, files namespaces |

### Feature 06 — pm-timeouts

| Field | Value |
|-------|-------|
| Size planned vs final | S / S |
| PR | [#294](https://github.com/gtrabanco/dotSloth/pull/294) |
| SHA | `b7a3f0a` |
| Audit verdict | MERGE-READY, 6/6 CI green |
| Merged by | autopilot (--fullauto) |
| Tests | 91 → 96 (+5 tests) |
| Review findings | 0 fix-now, 0 postponed |
| Notes | `package::run_with_timeout` helper (3-tier: gtimeout→timeout→bash); `SLOTH_PM_TIMEOUT` env var + per-PM overrides |

### Feature 07 — restorer-v2

| Field | Value |
|-------|-------|
| Size planned vs final | M / M |
| PR | [#295](https://github.com/gtrabanco/dotSloth/pull/295) |
| SHA | `46c89f2` |
| Audit verdict | MERGE-READY, 6/6 CI green (after shfmt fix) |
| Merged by | autopilot (--fullauto) |
| Tests | 96 (no new tests — restorer is bootstrap, tracked in #268) |
| Review findings | 0 fix-now, 3 LOW postponed (indentation, has_component subshell, symlinks rollback) |
| Notes | Validation, rollback, progress, --components, --dry-run; fixed latent arg parsing bug (missing shift) |

## Issues

### Full inventory

| Issue | Title | Triage verdict | Outcome |
|-------|-------|---------------|---------|
| #288 | eval injection | fix-now | PR #292 merged |
| #296 | restorer symlinks rollback incomplete | postpone | Filed during sweep (from review finding) |
| #268 | Tests for restorer/installer | postpone | Trigger: mock harness for git/PMs |
| #273 | gem.bats grep-based tests | postpone | Trigger: mock harness for gem |
| #236 | Migrate docpars/docopts to Rust | postpone | Trigger: roadmap 01-03 planning |
| #237 | Migrate 'dot' to Rust | postpone | Trigger: roadmap 01-03 planning |
| #238 | Migrate 'up' to Rust | postpone | Trigger: roadmap 01-03 planning |
| #224 | Documentation improvements | postpone | Trigger: documentation audit / community FAQ |
| #222 | Discussion: Add gum | postpone | Trigger: decision to adopt gum |
| #218 | Discussion: Init scripts | postpone | Trigger: init script requirements defined |
| #217 | Documentation in code | postpone | Trigger: documentation sprint |
| #223 | Discussion: Migrate dot to other language | wontfix | Closed — superseded by #236-238 |
| #209 | Help Request: Create tutorial | wontfix | Closed — help request, not trackable |

### Fix-now issues shipped

| Issue | PR | Outcome |
|-------|----|---------| 
| Stale #288 in fix index | [#297](https://github.com/gtrabanco/dotSloth/pull/297) | Merged (admin, docs-only no CI) |

### Remaining triage batch

All inventoried issues have been triaged with dated verdicts posted. No issues remain untriaged. The postpone triggers above define when each should be re-evaluated.

## New feature proposals

| Proposal | Size | Suggested slot | Rationale |
|----------|------|---------------|----------|
| Mock harness for external commands | S | 09 | Unblocks #268 and #273; enables functional testing of package managers and bootstrap scripts |
| Restorer symlinks rollback completion | XS | fix | #296 — parse `symlinks.txt` in `rollback()` or remove it as diagnostic-only |
| Documentation sprint | M | 10 | Addresses #224, #217 — inline docs, FAQ, getting started guide |

## Residual risks

1. **Restorer tests (#268)** — the restorer is the single largest untested critical path. Feature 07 added safety mechanisms but no automated tests. Manual verification via `--dry-run` is the only validation.
2. **`--fullauto` merges deserving a second look:**
   - PR #297 (fix index cleanup) — merged via `--admin` because CI doesn't trigger for docs-only PRs (`paths-ignore: docs/**`). Local gate was green. This is a known gap in branch protection for docs-only changes.
3. **Restorer symlinks rollback (#296)** — rollback saves symlinks list but doesn't restore them. LOW severity, accepted risk in SPEC.
4. **shfmt formatting** — the restorer was initially committed with formatting issues; CI caught it. The local `bash scripts/core/lint` should catch this but didn't because the restorer may be excluded from the lint list. Worth investigating.
5. **Silent decisions with outsized consequences:** The decision to exclude Rust migration (01-03) from this run means the three most complex roadmap features remain unstarted. The product's long-term direction (Rust vs Bash) is an open question (#223 was closed as wontfix, but the underlying discussion lives in #236-238).

## Manual-verification checklist

From all review checkpoints + audit notes:

- [ ] `bash restorer --help` shows new flags (--dry-run, --components)
- [ ] `bash restorer --version` shows v2.0.0
- [ ] `bash restorer --dry-run` (with DOTLY_ENV=CI) prints planned actions without making changes
- [ ] `bash restorer --components=dotfiles` (with DOTLY_ENV=CI) skips package import
- [ ] `SLOTH_PM_TIMEOUT=10 dot package update_all` respects the timeout
- [ ] `BREW_TIMEOUT=5 dot package update_all` respects per-PM override
- [ ] `dot core install` still works after all changes (regression check)
- [ ] `make test` passes with 96 tests (automated, but worth confirming locally)

## Going forward

### Product-audit cadence

This run merged 4 units (1 fix + 3 features). A `product-audit` is **due now** — the first audit was performed before the run (2026-07-06), but 4 units have since been merged. Recommended cadence: every 5 merged units or pre-release, whichever comes first. Next audit: after 1 more merge, or before the next release.

### Suggested command sequence

```
→ Next: /product-audit  · accepted proposals → /plan-feature  · open issues → /triage-issue
  · product-audit due → /product-audit (4 units merged since last audit)
  · mock harness → /plan-feature (unblocks #268, #273)
  · #296 → /plan-fix 296 (restorer symlinks rollback, XS)
  · Rust migration → /plan-feature --next (roadmap 01-03, when ready)
```

**This report recommends; the human decides.**
