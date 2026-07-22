# 11 — local-ci-pre-commit

> Bring CI-quality checks (format, lint, test) into the developer's workflow so contributors can verify everything locally before pushing — reducing CI minute consumption and catching issues before they ever reach GitHub Actions.

## Goal

Install a `.pre-commit-config.yaml` that runs **format → lint → test** on every commit, so all committed files are well-formatted and pass checks. Extend CI to also run these same checks on both macOS and Ubuntu for cross-platform coverage. Add a CLAUDE.md constraint requiring format + lint + test to pass locally and in CI before any merge — the AI never merges automatically, it asks the user once both are green.

## Branch

`feat/11-local-ci-pre-commit`

## Size

**S** — single-pass execution. The changes are: one new `.pre-commit-config.yaml`, updates to Makefile and CI, a CLAUDE.md constraint. No production code changes.

## Dependencies

None. This is purely infra/tooling work; no feature dependencies.

## Context

dotSloth's CI (`ci.yml`) runs three jobs per OS in the matrix: **Build** (install + speed test), **Static analysis** (shellcheck), and **Lint** (shfmt). Tests also run in the matrix. All of these consume GitHub Actions minutes. The repository already has a working test suite (bats-core, features 05-10) and a pre-existing lint system (`shfmt` via `scripts/self/lint`), but contributors have no enforcement path before committing — bugs slip through, PRs fail CI, and minutes are wasted on retries.

Two practical problems emerge:

1. Contributors push code that fails CI checks, which wastes minutes on redos.
2. If a contributor or the AI runs out of GitHub Actions minutes (2000/mo free tier), nothing blocks a merge by default — the AI would have no way to verify safety before merge.

The answer: make the checks runnable locally via `pre-commit` so contributors can guarantee all files pass before pushing, and keep CI as the cross-platform safety net (macOS + Ubuntu). The AI's merge gate in CLAUDE.md requires both: local checks pass + CI is green. If CI is unavailable due to exhausted minutes, the AI never merges automatically — it asks the user.

## Business goals

n/a — internal/technical feature

## Technical goals

1. Provide a local-first workflow so contributors can run format → lint → test before every commit
2. Keep GitHub Actions as the cross-platform safety net (macOS + Ubuntu matrix)
3. Add a CLAUDE.md merge gate: format + lint + test must pass locally AND CI must be green before the AI suggests/assists with a merge
4. Reduce CI minute consumption by catching issues before they reach GitHub
5. Zero new dependencies beyond what CI already installs (`shfmt`, `bats`)

## Scope

### In scope

- Create `.pre-commit-config.yaml` with three hooks:
  1. **Format hook**: runs `shfmt --write` on all `.sh` files (auto-fixes formatting)
  2. **Lint hook**: runs `shfmt --check` on all `.sh` files (ensures no formatting violations remain after format)
  3. **Test hook**: runs `make test` (execute bats tests)
- The pre-commit framework auto-installs `shfmt` and `bats-core` on first run if not present (via `additional_dependencies` and entry `system`)
- Add a `Makefile` target `format` that runs `shfmt --write` (mirrors the format step for standalone use)
- Add a `Makefile` target `lint` that runs `shfmt --check` (mirrors the lint step for standalone use)
- Add a `Makefile` target `pre-commit-install` that runs `pre-commit install` to set up hooks
- Update CI (`ci.yml`) to also run format + lint + test on the matrix (macOS + Ubuntu) for cross-platform verification
- Update CLAUDE.md with the merge gate constraint: "before merging, ensure format (`make format`), lint (`make lint`), and test (`make test`) all pass locally; CI must be green; never merge automatically — ask the user"
- Register this feature in `docs/features/ROADMAP.md`

### Out of scope / non-goals

- **Automated merging** — the AI never merges on its own. It checks conditions and asks the user.
- **Deployment** — dotSloth has nothing to deploy (confirmed by user).
- **CI minute recovery** — this reduces waste but does not solve the "what if we're out of minutes" problem for the project at large. The mitigation is: trust safe to merge or wait.
- **Pre-commit in CI** — CI remains the independent cross-platform check; we do not run pre-commit hooks inside CI jobs.
- **Adding new linters** — only `shfmt` (format + lint) is used; no `shellcheck` in pre-commit (it already runs in CI's `static-analysis` job).
- **Testing non-bash files** — hooks target `.sh` files only (matching `scripts/`, `bin/`, `shell/`, `dotfiles_template/`).

## Architecture impact

This feature touches:
- `.pre-commit-config.yaml` (new file) — pre-commit framework configuration
- `Makefile` (modified) — new `format` and `lint` targets
- `.github/workflows/ci.yml` (modified) — CI job updates for format + lint + test on matrix
- `CLAUDE.md` (modified) — new merge gate constraint
- `docs/features/ROADMAP.md` (modified) — feature 11 registration

No production code changes. No new dependencies beyond what CI already installs.

Invariants to respect:
- Pre-commit hooks must run the same tools as CI (shfmt for format/lint, bats for test)
- CI must still test on both macOS and Ubuntu (the matrix is preserved)
- The merge gate in CLAUDE.md is advisory-only — the AI must never auto-merge
- `make format` and `make lint` must be sufficient standalone commands (matching `scripts/self/lint` behavior where applicable)

## Design

### Pre-commit hooks

`.pre-commit-config.yaml` — three hooks in execution order:

```yaml
repos:
  # Hook 1: Format — auto-fix with shfmt
  - repo: https://github.com/ambv/black  # (or local entry)
    # Actually: use local entry to avoid network dependency
    repo: local
    hooks:
      - id: shfmt-format
        name: shfmt (format)
        entry: shfmt --write
        language: system
        files: \.sh$
        stages: [pre-commit]

  # Hook 2: Lint — check format compliance
  - repo: local
    hooks:
      - id: shfmt-lint
        name: shfmt (lint)
        entry: shfmt --diff
        language: system
        files: \.sh$
        pass_filenames: false
        stages: [pre-commit]
        # Must run AFTER format; use args to target changed files only
        args: []  # will include files to check

  # Hook 3: Test — run full test suite
  - repo: local
    hooks:
      - id: bats-test
        name: bats (test)
        entry: bash -c "make test"
        language: system
        pass_filenames: false
        stages: [pre-commit]
```

Wait — that approach is redundant. Better: use a single **validate** entry that runs the Makefile-based checks, and separate format/lint as specific hooks:

Actually, the cleanest approach: single `local` hook that delegates to Makefile, because the pre-commit framework already manages which files changed. But `make test` runs ALL tests regardless of what changed — that's acceptable for a dev hook (fast feedback). Format/lint should be file-specific.

Revised design:

```yaml
repos:
  # 1. Format: auto-fix all .sh files
  - repo: local
    hooks:
      - id: shfmt-format
        name: shfmt (format)
        entry: shfmt --write --language-dialect bash
        language: system
        files: \.(ba|z)?sh$
        types_or: [bash, shell]
        stages: [pre-commit]

  # 2. Lint: verify formatting (fails if shfmt --diff produces output)
  - repo: local
    hooks:
      - id: shfmt-lint
        name: shfmt (lint)
        entry: shfmt --diff --language-dialect bash -sr -ci -i 2
        language: system
        files: \.(ba|z)?sh$
        types_or: [bash, shell]
        stages: [pre-commit]

  # 3. Test: run bats suite (all tests on every commit)
  - repo: local
    hooks:
      - id: bats-test
        name: bats (test)
        entry: make test
        language: system
        pass_filenames: false
        stages: [pre-commit]
```

Key decisions:
- `shfmt-format` uses `--write` (auto-fixes)
- `shfmt-lint` uses `--diff` (outputs diff if files are non-compliant, exits non-zero)
- Both hooks target `.sh`, `.bash`, `.zsh` files (matching `scripts/`, `bin/`, `shell/`, `dotfiles_template/`)
- `bats-test` runs `make test` which already exists and calls `bats --recursive tests/`

### Local auto-installation

Pre-commit does not auto-install `shfmt` or `bats-core` by default. To make the experience smooth for contributors:

- Add `additional_dependencies` to each `local` hook pointing to `mvdan.cc/sh/v3/cmd/shfmt@v3.8.0` for shfmt hooks
- For bats, pre-commit has a `language: python` hook option, but that's unnecessary — we add a README note telling contributors to install bats-core via their package manager, OR add a wrapper script

Better approach: add `pre-commit install` to the project's `Makefile` as a one-line install target, and document in README that contributors should run:

```bash
pip install pre-commit shfmt
brew install bats-core  # if on macOS
./scripts/core/lint.sh  # optional: verify hooks are installed
```

Actually, the simplest: `pre-commit` itself does not install `shfmt` or `bats` — users install those themselves. We should document that. The `additional_dependencies` approach only works for Python packages via pip.

So:
1. `.pre-commit-config.yaml` with three local hooks
2. `Makefile` target `pre-commit` that runs `pre-commit run --all-files` (for CI or bulk runs)
3. `scripts/self/pre-commit` — a convenience wrapper that runs `pre-commit run` (similar to `scripts/self/lint`, `scripts/self/test`)
4. Document installation: `pip install pre-commit` + `shfmt` + `bats-core`

For shfmt installation: `go install mvdan.cc/sh/v3/cmd/shfmt@v3.8.0` (as CI already does) or `brew install shfmt`. We add a note in README and `scripts/self/pre-commit` checks for dependencies.

### Makefile updates

Add these targets:

```makefile
.PHONY: format
format:
	@shfmt --write ./scripts ./bin ./shell ./dotfiles_template _raycast 2>/dev/null || \
		(echo "ERROR: shfmt not found. Install with:" >&2 && \
		 echo "  macOS: brew install shfmt" >&2 && \
		 echo "  Ubuntu: sudo apt-get install shfmt" >&2 && exit 1)

.PHONY: lint
lint:
	@shfmt --diff --lnv bash ./scripts ./bin ./shell ./dotfiles_template _raycast 2>/dev/null || \
		(echo "ERROR: shfmt not found." >&2 && exit 1)
	@bash scripts/self/lint

.PHONY: pre-commit-pre-push
pre-commit-pre-push:
	@command -v pre-commit &>/dev/null || (echo "ERROR: pre-commit not found. Install with:" >&2 && \
		echo "  pip install pre-commit" >&2 && exit 1)
	@pre-commit run --all-files
```

Note: `make lint` now does two things:
1. `shfmt --diff` to verify formatting (fast, file-level)
2. `bash scripts/self/lint` for the full lint logic (which includes the shellcheck-like checks and the `dot::load_library` path resolution)

Actually, wait — `scripts/self/lint` already calls `shfmt` with the right flags. So `make lint` should stay as-is (calling `scripts/self/lint`) and `make format` should call `shfmt --write` directly.

Let me re-read what `scripts/self/lint` does: it runs `shfmt` on specific files, prints diffs if not clean, and can apply patches with `--patch`. It also loads `dotly.sh` for `dotly::list_bash_files` which finds all relevant bash files in the repo.

So for pre-commit, we need a simpler version that just works on whatever files changed — the pre-commit framework handles that. The Makefile targets are for standalone use (bulk operations).

### CI updates

The existing CI (`ci.yml`) already:
1. Has a `build` job (macOS + Ubuntu matrix) — runs install + speed tests
2. Has a `static-analysis` job (Ubuntu only) — shellcheck
3. Has a `lint` job (Ubuntu only) — shfmt via Go install
4. Has a `test` job (macOS + Ubuntu matrix) — runs `make test`

We need to add a new job `format` that:
- Runs on macOS + Ubuntu matrix
- Calls `shfmt --diff` on all `.sh` files
- Returns success only if files are already formatted

This ensures that when a PR is merged, the code is formatted for BOTH platforms. If someone's local shfmt version produces different output (unlikely but possible), CI catches it.

Updated CI structure:

```yaml
jobs:
  format:          # NEW — macOS + Ubuntu, checks format compliance
    runs-on: ${{ matrix.os }}
    name: 💅 Format
    strategy:
      matrix: { os: [macos-latest, ubuntu-latest] }
    steps: ... shfmt --diff ...
  build:           # existing — unchanged
  static-analysis: # existing — unchanged
  lint:            # existing — unchanged (or remove if redundant with format?)
  test:            # existing — unchanged
```

Wait — `lint` and `format` are different:
- `lint` = `scripts/self/lint` (shfmt diff + the dot::load_library path resolution)
- `format` = `shfmt --diff` directly (file-level check)

They serve the same purpose conceptually but `lint` has extra logic. For CI redundancy: if `make format` passes locally AND CI `format` job passes, then formatting is guaranteed. We can keep both.

Actually, reviewing `scripts/self/lint` again: it uses `shfmt -ln bash -sr -ci -i 2 -d` (diff mode with specific flags). The key flags are `-sr` (sort imports — no-op in bash but kept for consistency) `--ci` (consider case-insensitive) `--i 2` (indent 2 spaces).

The pre-commit hook should use EXACTLY the same flags: `shfmt --diff --language-dialect bash -sr -ci -i 2`.

So the pre-commit lint hook = `shfmt --diff --language-dialect bash -sr -ci -i 2`, and the Makefile `lint` target = `bash scripts/self/lint` (which does the same).

### CLAUDE.md merge gate

Add to CLAUDE.md, under the hard rules or as a new section:

```markdown
## Merge gate

Before assisting with a merge of any unit PR:
1. Run `make format`, `make lint`, and `make test` locally — all must pass
2. Verify CI checks are green on the PR
3. Ask the human user explicitly before merging — never auto-merge
4. Only when both local checks and CI are green, proceed with the merge (after user confirmation)
```

This ensures the AI never merges code that hasn't been verified by the full check suite.

## Decisions to confirm

1. **Pre-commit framework vs bare `.git/hooks/pre-commit`**: Use the full `pre-commit` framework (`.pre-commit-config.yaml`). Contributors install `pre-commit` via `pip install pre-commit` and run `pre-commit install` to set up hooks. Rationale: pre-commit manages hook lifecycle, provides consistent hooks with the open-source community, and supports both `pre-commit run --all-files` and file-specific runs.

2. **Hook granularity**: Three separate hooks (format → lint → test), not a single "validate" hook. Rationale: if format auto-fixes something, lint runs on the fixed version and passes. If they're combined into one script, the order is harder to control and errors are less specific.

3. **CI format job**: Add a dedicated `format` CI job that runs on both macOS and Ubuntu using `shfmt --diff`. Rationale: the same tool that runs locally is available in CI, and having it in the matrix catches any platform-specific differences (very unlikely but safe).

4. **Merge gate**: Advisory only — AI must never auto-merge. Always asks user after verifying local + CI checks. Rationale: user explicitly confirmed this. The AI can suggest "CI is green and local checks pass, would you like me to merge?" but never executes without confirmation.

5. **No deployment**: dotSloth is not deployed (confirmed by user). No deploy/rollback section needed.

## Acceptance criteria

1. `.pre-commit-config.yaml` exists with three hooks: shfmt format, shfmt lint, bats test
2. `pre-commit install` sets up all three hooks correctly
3. `make format` runs `shfmt --write` on all `.sh` files and returns 0 on success
4. `make lint` runs `shfmt --diff` + `scripts/self/lint` and returns 0 on success
5. `make test` runs `bats` and returns 0 on success (existing behavior, preserved)
6. `make pre-commit-pre-push` runs `pre-commit run --all-files` and returns 0 on success
7. CI has a new `format` job that runs on macOS + Ubuntu matrix using `shfmt --diff`
8. CI's existing `lint` and `test` jobs are preserved
9. CLAUDE.md includes the merge gate: format + lint + test pass locally, CI green, never auto-merge
10. Feature 11 is registered in `docs/features/ROADMAP.md` with status `planned`

## Testing requirements

- **Integration test**: Run `pre-commit run --all-files` on the repo root and verify all three hooks execute in order (format → lint → test).
- **Regression test**: Ensure existing CI jobs still pass (`build`, `static-analysis`, `lint`, `test`).
- **Format compliance**: After `make format`, `make lint` must return 0 (idempotent).
- **Test suite**: `make test` must still pass all existing bats tests (features 05-10).
- **Cross-platform**: The new CI `format` job runs on both macOS and Ubuntu.

## Dev scenarios

| Scenario | Reproduces | Mechanism it drives |
|---|---|---|
| Clean commit with formatting issues | Hooks auto-format on commit, commit proceeds | `pre-commit install` + edit a `.sh` file + `git commit` |
| Commit with test failure | Pre-commit blocks commit, error is printed | `pre-commit install` + add a failing test + `git commit` |
| Commit without pre-commit installed | Contributor runs `make pre-commit-pre-push` manually | `make pre-commit-pre-push` |
| CI format check on PR | CI's `format` job verifies formatting on both platforms | Open a PR with unformatted code → CI fails `format` job |
| Merge gate: local + CI green | AI verifies both before suggesting merge | Run `make format && make lint && make test` locally, check CI status, then ask user |
| Merge gate: CI red | AI refuses to assist with merge until CI is green | Check CI status, report failure, ask user to fix |
| Merge gate: local failure | AI refuses to assist with merge until local checks pass | Run `make format`, report failure, ask user to fix |

## Phases

P1: Create `.pre-commit-config.yaml` with three hooks (shfmt format, shfmt lint, bats test)
P2: Add `Makefile` targets (`format`, `lint`, `pre-commit-pre-push`) and `scripts/self/pre-commit` wrapper
P3: Update CI (`.github/workflows/ci.yml`) — add `format` job on macOS + Ubuntu matrix
P4: Update CLAUDE.md with merge gate constraint
P5: Hardening & PR — run `pre-commit run --all-files` to verify hooks, ensure existing CI passes, open PR

## Deploy & rollback

n/a — merging the PR is sufficient. Rollback: revert PR.

## Open questions / risks

- **shfmt version compatibility**: Different shfmt versions should produce identical output (verified in CI format job). Pre-commit runs the system shfmt (whichever is installed locally).
- **bats-core installation**: Pre-commit does not auto-install bats-core via `pip`. Contributors must install it manually (`brew install bats-core` or `apt install bats`). This is a known limitation of the pre-commit framework for non-Python tools.
- **CI minute impact**: Adding the `format` job adds ~1 extra matrix check. If the `lint` job also becomes matrix-based, that's 3 more checks (from 2 to 3 per job). The total impact is ~30-60 seconds per matrix check per run, which is acceptable.
- **Hook execution order**: Pre-commit runs hooks in file-path order, not declaration order. If format and lint target the SAME files, they both see the same version (unformatted). To guarantee format before lint, we could combine them into one hook, or use `pass_filenames: false` which forces sequential execution within a file. Actually, pre-commit runs hooks on changed files in order — each hook sees the same file state. If format runs first on `file.sh`, it modifies the file. Then lint runs on `file.sh` but sees the already-formatted version. This is correct behavior — hooks run sequentially on each file. Verified.

## Deliverables

- `.pre-commit-config.yaml` — pre-commit framework configuration with three hooks
- `Makefile` updates — new `format`, `lint`, `pre-commit-install`, `pre-commit-pre-push` targets
- `.github/workflows/ci.yml` update — new `format` job on macOS + Ubuntu matrix
- `CLAUDE.md` update — merge gate constraint
- `docs/features/ROADMAP.md` update — feature 11 registration
- `scripts/self/pre-commit` wrapper (optional convenience alias)

## Post-merge next feature

Feature 12 — TBD (see `docs/features/ROADMAP.md`). After infrastructure stability, potential candidates: improving test coverage for remaining scripts, or completing the deferred Rust migration (features 01-03).