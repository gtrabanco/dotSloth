# Review findings — 12-skill-lockfile

Rows reconstructed from the `/audit-pr` BLOCKED verdict on PR #340
(`feat/12-skill-lockfile-p2-closeout` → `main`), per fold-findings Step 0 and
the audit-pr delivery contract.

| id | file:line | axis | severity | class | route | folded |
| F1 | .github/workflows/ci.yml (paths-ignore: docs/**) | review-verify | med | fix-now | fix-now | no |
| F2 | PR #340 body — `Closes #330` backticked (docs/features/12-skill-lockfile/SPEC.md) | workflow | med | fix-now | fix-now | no |
| F3 | Makefile — no `gate` target; docs gate is `static_analysis`+`lint` | review-verify | low | fix-now | fix-now | no |