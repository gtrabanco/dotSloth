# Review findings — 12-skill-lockfile

## Original findings (from prior audit)

Rows reconstructed from the `/audit-pr` BLOCKED verdict on PR #340
(`feat/12-skill-lockfile-p2-closeout` → `main`), per fold-findings Step 0 and
the audit-pr delivery contract.

| id | file:line | axis | severity | class | route | folded |
| F1 | .github/workflows/ci.yml (paths-ignore: docs/**) | review-verify | med | fix-now | fix-now | yes | *Folded: known project-wide CI config ignores all docs/* — not scoped to this feature |
| F2 | PR #340 body — Closes #330 backticked in review-findings.md | workflow | med | fix-now | fix-now | yes |
| F3 | Makefile — no `gate` target; docs gate is `static_analysis`+`lint` | review-verify | low | fix-now | fix-now | yes |

## New findings (PR #340 review pass — code, security, verify)

### BLOCKER / CRITICAL (must fix before merge)

| id | file:line | axis | severity | class | route | folded |
| B1 | .agentic-workflow/hooks/fullauto-merge.sh:48 — `repo` variable held JSON object, now fixed to `repo_owner` via `-q '.nameWithOwner'` extraction | code-correctness | critical | fix-now | fix-now | yes | Fixed: extracted `repo_owner` string, updated `repos/$repo` → `repos/$repo_owner` in gh api call |

### MEDIUM fixes (done before merge)

| id | file:line | axis | severity | class | route | folded |
| M1 | .agentic-workflow/hooks/fullauto-merge.sh:42-43 — `head_sha` and `remote_head` were identical (no-op check). Now re-fetches PR head before merge via `fresh_head=$(gh pr view "$pr" --json headRefOid -q '.headRefOid')` | code-correctness | medium | fix-now | fix-now | yes | Fixed: added pre-merge PR head re-fetch with clear error message |
| M2 | .agentic-workflow/hooks/fullauto-merge.sh:70 — `base64 --decode` is GNU-specific; replaced with portable `base64 -d` | code-portability | medium | fix-now | fix-now | yes | Fixed: replaced with POSIX-compatible `base64 -d` |
| M3 | .agentic-workflow/hooks/fullauto-merge.sh:109 — `gh pr merge` failure not handled by set -e; now wrapped with `|| fail "merge failed"` | code-correctness | medium | fix-now | fix-now | yes | Fixed: added error handler |
| M4 | docs/features/ROADMAP.md:row 12 — PR link #332 now updated to #340 | workflow | medium | fix-now | fix-now | yes | Fixed: updated PR link to #340 |

### LOW / INFO (nice-to-have, not blocking merge)

| id | file:line | axis | severity | class | route | folded |
| L1 | .agentic-workflow/hooks/guard-command.sh:3 — missing `set -o pipefail` (fullauto-merge.sh has it). Align for consistency. | arch-consistency | low | proposal | replan-in-unit | no | |
| L2 | .agentic-workflow/hooks/guard-command.sh:28 — `is_env_path` regex may false-positive on `config.env` (not dot-env). Tighten to `(^|/)\.env($|[./])` | security | low | proposal | replan-in-unit | no | |
| L3 | .agentic-workflow/hooks/guard-command.sh:55 — `printenv` pattern doesn't catch `echo "printenv"` (quote-delimited). Minor — guard is not a sandbox | security | low | ignore | ignore | no | Document: quote-delimited printenv is not a real attack vector |
| L4 | .agentic-workflow/hooks/guard-command.sh:60 — `.env.local`/`.env.production` paths not caught by `is_env_path` regex (only the command pattern catches them). Gap is low-severity | security | low | proposal | replan-in-unit | no | Append alternation `.env\.[a-zA-Z0-9_]` to regex |
| L5 | .agentic-workflow/hooks/tests/test-command-guard.sh — missing tests for `env > file.txt` bypass, `env 2>/dev/null`, `env FOO=bar` | test-coverage | low | proposal | replan-in-unit | no | Add expect_block tests for env bypass variants |
| L6 | .agentic-workflow/hooks/tests/test-fullauto-merge.sh — missing test for base64 decode failure and gh pr merge failure path | test-coverage | low | proposal | replan-in-unit | no | Add test fixtures |
| L7 | .agentic-workflow/hooks/adapters/copilot-guard.sh:18-20 — no stdout output on allow; Copilot may expect JSON. Consider `printf '{"continue":true}\n'` before exit 0 | code-correctness | low | proposal | replan-in-unit | no | |
| L8 | .agentic-workflow/hooks/adapters/pre-tool-guard.sh:14 uses `exec`, copilot-guard.sh calls as child process — inconsistent. Document why or unify | arch-consistency | low | proposal | replan-in-unit | no | Document design choice |
| L9 | docs/features/12-skill-lockfile/TASKS.md: P3 manual test gate still unchecked `[ ] Manual test: skills::import on valid YAML` | workflow | low | proposal | replan-in-unit | no | Either complete test or add justification note |