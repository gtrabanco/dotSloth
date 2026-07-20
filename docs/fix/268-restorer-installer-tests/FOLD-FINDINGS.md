# Fold Findings — fix/268-restorer-installer-tests

**Date:** 2026-07-20
**PR:** #324
**Branch:** fix/268-restorer-installer-tests
**Review mode:** --adversarial 2 (R1 correctness/logic, R2 security/inputs)

---

## Merged Findings Table

| # | file:line | Finding | Sev | Class | Source | Route |
|---|---|---|---|---|---|---|
| F1 | SPEC.md:67-71 | Acceptance criteria checkboxes unchecked despite P1-P3 complete | low | spec-drift | review | Tick checkboxes |
| F2 | restorer.bats:29+ | Test bloat — extracts unused helpers (`_w`,`_a`,`_e`,`_s`) that tested functions never call | low | test-bloat | R1 | Remove unused extractions |
| F3 | restorer.bats:152-153 | Fragile glob backup-finding heuristic (`ls -d *.back`) can match stale dirs from prior runs | low | test-reliability | R1+R2 | Use unique temp dir naming |
| F4 | installer.bats:57 | Predictable PID-based temp path (`/tmp/dotSloth-installer-test-$$`) instead of `mktemp -d` | medium | security | R2 | Use temp_dir helper |
| F5 | installer.bats:57-62 | Inconsistent temp dir strategy — installer uses hardcoded path, restorer uses `temp_dir()` | low | inconsistency | R2 | Standardize on `temp_dir()` |
| F6 | restorer.bats | Missing color variable definitions (`$red`,`$green`,`$purple`,`$normal`) in eval'd env — cosmetic only | low | test-quality | review | Extract or define vars |
| F7 | restorer:133 | `rollback()` silently returns 0 when rollback_dir exists but dotfiles subdir missing | medium | production-bug | R1 | **Out of scope** (test-only PR) |
| F8 | restorer:174 | `backup_dotfiles_dir` runs `mkdir -p` after `mv`, creating spurious dirs of dead path | medium | production-bug | R1 | **Out of scope** (test-only PR) |
| F9 | restorer.bats | `backup_dotfiles_dir` else-branch not exercised — only if-branch tested | medium | test-gap | R1 | Add else-branch test |
| F10 | installer:23,27 | `_q`/`_yq` use `eval` indirection — production code, out of scope | low | production-design | R2 | **Out of scope** |

## Verified False Positives

| Claim | Reviewer | Verdict | Evidence |
|---|---|---|---|
| awk extraction leaks `start_sudo`/`stop_sudo` side effects | R1 | **FALSE** | Extraction produces 14 lines (create_dotfiles_dir only); verified via `awk ... \| wc -l` |
| `start_sudo` background sleep loop leaks into test harness | R1 | **FALSE** | `start_sudo` is never extracted; extraction stops at function's closing `}` |
| `trap` from restorer global scope persists via eval | R2 | **FALSE** | Only function bodies extracted via `_extract_func`, not global scope |

## Triage

### Fix-now (in scope for this test-only PR)

| # | Action |
|---|---|
| F1 | Tick acceptance criteria checkboxes in SPEC.md |
| F2 | Remove unused helper extractions from restorer.bats setup (cosmetic, reduces eval surface) |
| F3 | Use `temp_dir`-derived backup paths to avoid stale glob matches |
| F4 | Replace hardcoded PID temp path with `temp_dir()` in installer.bats |
| F5 | Standardize both test files on `temp_dir()` from `tests/helpers/setup.bash` |
| F6 | Define color variables in test setup or extract them |
| F9 | Add else-branch test for `backup_dotfiles_dir` (non-existent path scenario) |

### Deferred (out of scope — production bugs in restorer)

| # | Issue | Reason |
|---|---|---|
| F7 | `rollback()` silent success on missing dotfiles subdir | Production code bug, not test code |
| F8 | `backup_dotfiles_dir` redundant `mkdir -p` after `mv` | Production code bug, not test code |
| F10 | `_q`/`_yq` eval indirection | Production design pattern, not test code |

### Ignored (inherent to test pattern)

| # | Issue | Reason |
|---|---|---|
| eval in test setup | Both reviewers flagged `eval` of extracted functions | Inherent to bats test pattern for monolithic scripts; no alternative without refactoring production code |

## Manual Verification Checklist

| Check | Status |
|---|---|
| `bats tests/core/restorer.bats` — 14/14 pass | PASS |
| `bats tests/core/installer.bats` — 3/3 pass | PASS |
| `bats --recursive tests/` — 177/177 pass, no regressions | PASS |
| shfmt/shellcheck | **NOT AVAILABLE** in this environment (noted in progress.md P3) |
| Branch in sync with remote | PASS |
| Git status clean | PASS |
| All commits follow `<type>(<scope>): <summary>` | PASS |
| No production code changes | PASS (5 files: 2 .bats, 3 docs) |

## SPEC Drift

The SPEC acceptance criteria (lines 67-71) are **unchecked** despite all work being complete and P1-P3 phases checked. This is a documentation hygiene issue, not a correctness issue. All criteria are met:

- `tests/core/restorer.bats` created with 14 test cases (≥4) ✓
- `tests/core/installer.bats` created with 3 test cases (≥2) ✓
- All tests pass ✓
- No existing tests broken ✓
- shfmt+shellcheck: not available in CI environment (documented in progress.md)
