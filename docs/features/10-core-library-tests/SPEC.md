# 10 — core-library-tests

> Feature specification. The doc read at the start of the workflow. Fill every
> section. Detailed phase tasks live in `PLAN.md` / `TASKS.md`, generated in
> planning from this spec.
>
> Copy this folder to `docs/features/NN-<feature-slug>/` and register the feature
> in `docs/features/ROADMAP.md` before starting.

## Goal

Add functional (behavioral) tests for the four most critical core libraries —
`array.sh`, `str.sh`, `json.sh`, `git.sh` — which currently have zero or
smoke-level-only test coverage. This closes the gap surfaced by the 2026-07-06
product audit (#301, MEDIUM severity): bugs in core library logic currently go
undetected because ~29 of 107 existing tests are "is defined" existence checks,
not behavior assertions.

## Branch

`feat/10-core-library-tests`

## Size

**S** — four new `.bats` files, no source changes, no architecture impact. A
single implementation pass (XS/S path): this SPEC is the only planning artifact.

## Dependencies

- **Hard:** Feature 09 (`mock-harness`, merged via #303) — provides
  `mock_command` / `unmock_command` / `clear_mocks` in `tests/helpers/mock.sh`,
  used to mock the `git` external command for `git.sh` tests that should not
  depend on a real repository's state.
- **Soft:** `bats-core` (already required by `make test`).

## Context

The 2026-07-06 product audit found that `tests/core/*.bats` are mostly
smoke-level (`declare -f … is defined` assertions). The libraries with the
least coverage are exactly the most reused:

- `array.sh` — used by package manager precedence logic (`array::substract`,
  `array::union` in `scripts/package/src/package.sh`).
- `str.sh` — used everywhere (`str::to_upper`, `str::contains`).
- `json.sh` — used by package dump/import (`json::to_yaml`, `json::is_valid`).
- `git.sh` — ~30 functions, used by every git command and the auto-updater.

Feature 09 (mock-harness) shipped `tests/helpers/mock.sh` with
`mock_command <cmd> [--exit-code N] [--stdout "text"]`, which makes it possible
to test `git.sh` functions that shell out to `git` without a real repo.

## Business goals

Internal tool — no external business outcome. The technical goal (below) is the
whole story.

## Technical goals

Every public function in `array.sh`, `str.sh`, `json.sh`, and `git.sh` has at
least one behavioral test (happy path + one edge case where the function has
meaningful failure modes). The test count rises from 107 to ~160+.

## Scope

### In scope

Four new test files under `tests/core/`:

1. `tests/core/array.bats` — `array::union`, `array::disjunction`,
   `array::difference`, `array::exists_value`, `array::substract`,
   `array::uniq_unordered`.
2. `tests/core/str.bats` — `str::split`, `str::contains`, `str::to_upper`,
   `str::to_lower`, `str::join`.
3. `tests/core/json.bats` — `json::to_yaml`, `json::is_valid`.
4. `tests/core/git.bats` — the public `git::*` functions, using the mock harness
   for the `git` external command where a real repo is not needed, and a temp
   git repo (created in the test) for state-dependent functions
   (`git::is_in_repo`, `git::current_branch`, `git::is_clean`, etc.).

No changes to `scripts/core/src/*.sh` — this feature adds tests only. If a test
reveals a bug, the bug is filed as a separate issue (out of scope here).

### Out of scope / non-goals

- `yaml.sh`, `collections.sh`, `templating.sh` — issue #301 lists them as
  "no tests" but ranks array/str/json/git as the four to do first. These three
  become a follow-up issue (proposed in the report).
- Restorer/installer tests (#268) — separate issue, different bootstrap path.
- `gem.bats` functional tests (#273) — separate issue.
- Fixing any bug a new test reveals — filed as a tracked issue, not inlined.

## Architecture impact

None. Tests live under `tests/core/` and source libraries via the existing
`tests/helpers/setup.bash` harness (which sources `_main.sh`). No new
dependencies on `scripts/core/src/` internals beyond what the test harness
already establishes. The mock harness (`tests/helpers/mock.sh`) is used as
designed by feature 09.

Invariants preserved:
- Core libraries are sourced, not executed — tests source them via setup.bash.
- No test modifies `scripts/` — read-only verification.
- `tests/helpers/mocks/` is prepended to PATH by setup.bash; mocks are cleaned
  per-test or per-suite.

## Design

### Test file conventions (match existing `tests/core/files.bats`)

```bash
#!/usr/bin/env bats
# bats file=true
load "../helpers/setup"
@test "function::name does X" { … }
```

Assertions: `[ "$status" -eq N ]`, `[ "$output" = "expected" ]`, `run func …`.
No new helpers — use `temp_file` / `temp_dir` from setup.bash.

### array.sh — pure functions, no mocks

| Function | Tests |
|---|---|
| `array::union a b c` | dedup + sort order; empty input |
| `array::disjunction` | only-unique elements; all-duplicate input |
| `array::difference` | only-duplicate elements; all-unique input |
| `array::exists_value val arr…` | found → 0; not found → 1; <2 args → 1 |
| `array::substract val arr…` | removes matching; keeps all when not found |
| `array::uniq_unordered arr…` | `eval $(…)` then `declare -p` shape; order preserved |

### str.sh — pure functions, stdin/arg variants

| Function | Tests |
|---|---|
| `str::split text delim` | multi-char split; single char; empty |
| `str::contains sub str` | true/false exit codes |
| `str::to_upper` | arg form + stdin form |
| `str::to_lower` | arg form + stdin form |
| `str::join glue f rest…` | joins with glue; single element; empty glue |

### json.sh — depends on `yq` (python-yq)

Guard each test: `skip` if `yq` is not installed (`command -v yq`), because
mocking yq would test nothing — it is a real dependency. The CI image has yq
installed by the installer step.

| Function | Tests |
|---|---|
| `json::is_valid` | valid JSON → 0; invalid → 1; file + stdin forms |
| `json::to_yaml` | round-trip a known JSON → expected YAML; file + stdin |

### git.sh — mock harness + temp repo

Two tiers:

1. **Temp real repo** (integration-style) for state functions: create a repo
   with `git init` in `temp_dir`, make a commit, then test
   `git::is_in_repo` → 0, `git::current_branch`, `git::is_clean` → 0 (clean) /
   1 (after `touch`), `git::current_commit_hash` returns a SHA, etc. Teardown:
   `rm -rf` the temp dir.

2. **Mock harness** for functions that call `git` with specific args and
   inspect output: `mock_command git --stdout "v1.2.3"` then test
   `git::remote_latest_tag_version` returns the mocked value; `mock_command git
   --exit-code 1` then test `git::check_remote_exists` returns 1. `clear_mocks`
   in teardown.

Not every one of the ~30 `git::*` functions needs both tiers — cover the most
used: `is_in_repo`, `current_branch`, `is_clean`, `current_commit_hash`,
`local_branch_exists`, `remote_branch_exists`, `local_latest_tag_version`,
`remote_latest_tag_version`, `check_branch_is_behind`, `is_valid_commit`,
`add_to_gitignore`. ~15-20 tests.

## Decisions to confirm

1. **json.sh skip-when-absent** — chosen: `skip` if yq missing rather than mock.
   Rationale: yq is a real dependency; mocking it tests the mock, not the
   function. CI has yq; local devs are warned by the skip message.
2. **git.sh temp repo vs all-mock** — chosen: both, tiered. Pure state checks
   use a real temp repo (integration, higher confidence); output-parsing
   functions use mocks (deterministic, no repo setup cost).
3. **No source changes** — if a test reveals a bug, file an issue; do not fix
   inline. Keeps this PR test-only and reviewable.

## Acceptance criteria

- [ ] `tests/core/array.bats` exists and covers all 6 `array::*` functions.
- [ ] `tests/core/str.bats` exists and covers all 5 `str::*` functions.
- [ ] `tests/core/json.bats` exists and covers both `json::*` functions (with
      skip guards for missing yq).
- [ ] `tests/core/git.bats` exists and covers ≥10 `git::*` functions.
- [ ] `make test` passes with the new files (total ≥ 150 tests).
- [ ] `bash scripts/self/static_analysis && bash scripts/self/lint` green.
- [ ] No file under `scripts/` is modified.

## Testing requirements

This feature IS tests. Layer: integration (real temp git repo) + unit
(pure-function assertions). Tooling: bats-core, the existing mock harness.
No new tooling.

## Dev scenarios

| Scenario | Reproduces | Mechanism it drives |
|---|---|---|
| `array::substract` with value not in array | keeps all elements | direct call + assertion |
| `str::to_upper` via stdin pipe | stdin form works | `echo x \| str::to_upper` |
| `json::is_valid` on malformed JSON | returns 1 | direct call |
| `git::is_clean` after untracked file | returns 1 | temp repo + touch |

## Phases

Single pass (S size). P1 = implement all four test files + run gate. The PR
opens at the end of P1.

## Deploy & rollback

n/a — merging is enough. Tests only; no runtime change.

## Open questions / risks

- **`array::uniq_unordered` uses `declare -p`** — the test must `eval` the output
  and inspect the declared array. Verify the eval pattern works under bats
  `run` (which captures stdout). RESOLVED: call directly (not via `run`) and
  `eval` the output in the test shell.
- **git mock pollution** — mocks in `tests/helpers/mocks/` persist across tests
  if not cleaned. RESOLVED: `teardown` calls `clear_mocks` in `git.bats`.

## Deliverables

- `tests/core/array.bats`
- `tests/core/str.bats`
- `tests/core/json.bats`
- `tests/core/git.bats`
- This SPEC (`docs/features/10-core-library-tests/SPEC.md`)
- ROADMAP.md row 10 flipped to `in-progress` → `done`

## Post-merge next feature

The roadmap's remaining planned features are 01-03 (Rust migration, out of
scope per the decision record). The natural follow-up is a new feature for
`yaml.sh`, `collections.sh`, `templating.sh` tests (proposed in the report), or
revisiting #268 (restorer/installer tests) now that the mock harness exists.
