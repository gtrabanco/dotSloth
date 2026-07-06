# Ship Roadmap — Decision Record

**Run mode:** `--fullauto` (auto-merge with non-negotiable safety floors)
**Founded:** 2026-07-06
**Profile:** Internal tool — stricter testing, more docs discipline

## Locked interview answers

### Round 1 — Product
- **What:** dotSloth — modular Bash dotfiles framework (fork of dotly/CodelyTV)
- **Scale:** Solo developer / small community
- **Lifespan:** Internal tool — daily driver, stricter quality bars
- **Ambition:** Stabilize and improve the existing Bash codebase; defer Rust migration

### Round 2 — Features
- **Scope:** Fixes + easy Bash features. Skip Rust migration (01-03).
- **Order (confirmed):**
  1. Fix #288 — eval injection in install_remote (security, fix-now)
  2. Feature 08 — test-coverage-expansion (sloth_update tests, from #267)
  3. Feature 06 — pm-timeouts (configurable timeouts for package managers)
  4. Feature 07 — restorer-v2 (validation, rollback, partial restore)
- **Out of scope:** Features 01-03 (Rust migration), #268 (restorer/installer tests), #273 (gem.bats grep tests)

### Round 3 — Stack & architecture
- **Stack:** Bash, shfmt + shellcheck, bats-core for tests
- **Architecture:** Modular monolith with context-based namespacing (see ARCHITECTURE.md)
- **No changes from substrate**

### Round 4 — Quality & ops
- **Test depth:** Workflow default (bats-core, integration over mocking) — stricter for internal tool
- **Verification gate:** `bash scripts/self/static_analysis && bash scripts/self/lint && make test`
- **CI:** GitHub Actions (already configured)
- **Deploy:** N/A — dotfiles framework

### Round 5 — Workflow & autonomy
- **Docs language:** English
- **Forge:** GitHub (`gh` authenticated as gtrabanco)
- **Git workflow:** Worktrees (per CLAUDE.md) — `git worktree add` under `../dotSloth-<branch>`
- **Merge policy:** `--fullauto` (dual-keyed: flag + this record)
- **Sensitive areas:** None for this run (dotfiles framework, no auth/payments/secrets)
- **Budget caps:**
  - Max iterations: 16 (4×4 units)
  - Red gate retries: 2 per unit
  - Review-fix cycles: 2 per unit
  - Audit-fix cycles: 2 per unit
- **Model routing:** Conductor at high; execution subagents at sonnet

## Safety floors (non-negotiable, evaluated fresh before every merge)

1. **Never merge red** — re-verify CI via `gh pr checks` at merge time; no-CI → fresh local gate run on PR head SHA
2. **Verdict freshness** — MERGE-READY must reference PR's current head SHA
3. **Sensitive-area pause** — none declared for this run
4. **Destructive-operation pause** — data-deleting diffs pause regardless
5. **Forge refusal is a signal** — never bypass branch protection or force-push
6. **Budget floors still bind** — no cap exempted by --fullauto

## Skills directory

Installed at: `/Users/gtrabanco/.agents/skills/`
- `plan-feature` — JIT feature planning
- `execute-phase` — phase execution (sonnet subagents)
- `review-change` — review checkpoints
- `audit-pr` — merge gate
