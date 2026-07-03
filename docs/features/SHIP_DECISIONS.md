# Ship Roadmap — Decision Record

**Run mode:** `--fullauto` (auto-merge with non-negotiable safety floors)
**Founded:** 2026-07-03
**Profile:** Throwaway/experimental — validate Rust migration viability before committing

## Locked interview answers

### Round 1 — Product
- **What:** dotSloth — modular Bash dotfiles framework (fork of dotly/CodelyTV)
- **Scale:** Solo developer / small community
- **Lifespan:** Throwaway/experimental — validate migration to Rust before committing
- **Ambition:** Stabilize existing bugs, validate tooling path, then decide on Rust migration

### Round 2 — Features
- **Scope:** Bugs first, then tech-debt. No roadmap features in this run.
- **Order (confirmed):**
  1. Fix #247 — pkill -f tmux destroys all system sessions
  2. Fix #246 — script::depends_on hangs in non-interactive contexts
  3. Fix #245 — Success message always shown despite failures
  4. Fix #233 — Auto-updater broken
  5. Fix #234 — Restorer broken
  6. Fix #235 — up command fails to parse updates
  7. Fix #255 — Reconcile DOTLY_PATH/SLOTH_PATH (tech-debt)
- **Out of scope:** All roadmap features (01-07), new feature proposals

### Round 3 — Stack & architecture
- **Stack:** Bash, shfmt + shellcheck, bats-core for tests
- **Architecture:** Modular monolith with context-based namespacing (see ARCHITECTURE.md)
- **No changes from substrate**

### Round 4 — Quality & ops
- **Test depth:** Workflow default (bats-core, integration over mocking)
- **Verification gate:** `bash scripts/self/static_analysis && bash scripts/self/lint && make test`
- **CI:** GitHub Actions (already configured)
- **Deploy:** N/A — dotfiles framework

### Round 5 — Workflow & autonomy
- **Docs language:** English
- **Forge:** GitHub (`gh` authenticated as gtrabanco)
- **Git workflow:** Worktrees (per CLAUDE.md) — `git worktree add` under `../dotSloth-<branch>`
- **Merge policy:** `--fullauto` (dual-keyed: flag + this record)
- **Sensitive areas:** None for this run (dotfiles bug fixes, no auth/payments/secrets)
- **Budget caps:**
  - Max iterations: 28 (4×7 units)
  - Red gate retries: 2 per unit
  - Review-fix cycles: 2 per unit
  - Audit-fix cycles: 2 per unit
- **Model routing:** Conductor at opus/high; execution subagents at sonnet

## Safety floors (non-negotiable, evaluated fresh before every merge)

1. **Never merge red** — re-verify CI via `gh pr checks` at merge time; no-CI → fresh local gate run on PR head SHA
2. **Verdict freshness** — MERGE-READY must reference PR's current head SHA
3. **Sensitive-area pause** — none declared for this run
4. **Destructive-operation pause** — data-deleting diffs pause regardless
5. **Forge refusal is a signal** — never bypass branch protection or force-push
6. **Budget floors still bind** — no cap exempted by --fullauto

## Skills directory

Installed at: `/Users/gtrabanco/.hermes/skills/`
- `plan-feature` — JIT feature planning
- `execute-phase` — phase execution (sonnet subagents)
- `review-change` — review checkpoints
- `audit-pr` — merge gate
