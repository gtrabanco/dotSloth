# PLAN: 12-skill-lockfile

> Engineering plan. Generated from `SPEC.md` before `execute-phase`.
> Phase tasks are in `TASKS.md`.

## Branch

`feat/12-skill-lockfile`

## Size

**M** — four phases (P1–P4).

## Phases

### P1 — Core infrastructure

**Goal**: YAML parser/writer, wrapper scripts producing `.skill-lock.json`, and
the skeleton of `skills.sh` so every function signature exists (even if no-ops).

1. Create `scripts/package/src/lib/yaml.sh` skeleton with `yaml::write_*` and
   `yaml::read_*` function declarations plus `set -euo pipefail` header.
2. Implement `yaml::write_value` — single key=value line with comment prefix.
3. Implement `yaml::write_array` — `key:\n  - item\n  - item` format.
4. Implement `yaml::write_document` — orchestrates comment header, key-value,
   and array sections, writes to file.
5. Implement `yaml::read_value` — single-line parser: strips leading spaces,
   splits on first `=`, returns the value for a key.
6. Implement `yaml::read_array` — parser that reads a multiline array starting
   at `key: [<items>]` (inline) or `key:\n  - item` (block) forms.
7. Validate yaml.sh with `shfmt` and `shellcheck`.

8. Create `scripts/package/src/wrappers/skills-add-bunx.sh` with argument
   parsing (`<provider> [#<branch>] --agent <agent> [-g] [-y]`), delegation to
   `bunx skills add`, and `.skill-lock.json` write on success.
9. Implement wrapper's directory diffing to detect installed skill path.
10. Implement `.skill-lock.json` write with correct JSON schema (provider,
    branch, agents, command, installed_at).
11. Create `scripts/package/src/wrappers/skills-add-npx.sh` — same structure as
    `skills-add-bunx.sh` but delegates to `npx skills add`.
12. Validate wrapper scripts with `shfmt` and `shellcheck`.

13. Create `scripts/package/src/package_managers/skills.sh` skeleton importing
    `_main.sh`, sourcing `yaml.sh`, and declaring `dump` and `import` functions
    with `set -euo pipefail`.
14. Implement `skills::setup` — no-op (skills have no setup step).
15. Validate `skills.sh` with `shfmt` and `shellcheck`.

**Completion gate**: `bash scripts/self/static_analysis` and `bash scripts/core/lint` pass.
No feature tests yet — YAML, wrappers, and skeleton are unit-tested individually.

### P2 — Dump flow

**Goal**: `skills::dump` discovers skills via `.skill-lock.json` (primary) and
`package.json` (fallback), groups by provider, writes YAML.

1. Implement `skills::_discover_skills_with_lockfiles` — scans
   `$HOME/.agents/skills/`, reads `.skill-lock.json` per directory, returns
   structured data (provider, branch, agents, command, name).
2. Implement `skills::_discover_skills_from_package_json` — for skills without
   lockfiles, reads each skill's `package.json`, matches dependency keys against
   `<skill-name>` or `<skill-name>#<branch>` patterns.
3. Implement `skills::_merge_discoveries` — primary results + fallback (marked
   as fallback with `command: unknown` or detected command).
4. Emit warnings for each fallback-discovered skill (documented in `Open questions`).
5. Implement `skills::_group_by_provider` — deduplicates skills by provider name,
   groups agents across skills.
6. Implement `skills::dump` — orchestrates discovery, merging, grouping, and
   calls `yaml::write_document` to produce `$DOTFILES_PATH/agents/skill-lock.yaml`.
7. Handle `$HOME/.agents/` not existing — produce valid YAML with empty providers.
8. Log dump summary: primary count, fallback count, total groups.

**Completion gate**: `bash scripts/self/static_analysis` and `bash scripts/core/lint` pass.
Dump tested with manually populated `$HOME/.agents/skills/` directory.

### P3 — Import flow

**Goal**: `skills::import` parses YAML, validates entries, constructs and executes
install commands, verifies post-install, reports summary.

1. Implement `skills::import` — checks for `$DOTFILES_PATH/agents/skill-lock.yaml`,
   reads and parses the YAML document.
2. Implement `skills::_parse_yaml_document` — calls `yaml::read_value` and
   `yaml::read_array` to extract `format`, provider list, skill specs, and agent list.
3. Implement `skills::_parse_yaml_raw` — fallback parser that reads the YAML
   file line-by-line without `yaml.sh` dependencies, returning raw key-value
   pairs for validation (handles malformed YAML).
4. Implement validation: check `format` field matches `skill-lock-v1`, verify
   each provider/skill/agent triplet has required fields.
5. Implement `skills::_execute_single_install` — constructs the command from
   recorded `command` field, executes, captures exit code, returns status.
6. **IMPORTANT**: Wrap `_execute_single_install` in a function that does NOT have
   `set -euo pipefail` (per arch.md: core libraries intentionally omit `set -e`).
7. Implement failure aggregation: track total, succeeded, failed per entry.
8. Implement `skills::_verify_install` — after install, check that the skill
   directory exists in `$HOME/.agents/skills/` and that `.skill-lock.json` was
   created (if wrapper was used).
9. Report summary to stdout: total, succeeded, failed, per-entry details.
10. Exit 0 if any success, exit 1 only if ALL installations fail (per the
    error/edge states spec).

**Completion gate**: `bash scripts/self/static_analysis` and `bash scripts/core/lint` pass.
Import tested with manually created `skill-lock.yaml` file and mocked installs.

### P4 — Integration & hardening

**Goal**: Register `skills` as a package manager, integration tests for all dev
scenarios, wrapper documentation, shellcheck/shfmt gate, edge case hardening.

1. Register `skills` in `scripts/package/src/_main.sh`'s
   `get_available_package_managers` array (or equivalent dispatch function).
   Verify the existing `dump`/`import` iteration picks it up automatically.
2. Run `dot package dump` with pre-populated skills directory — verify YAML structure.
3. Run `dot package import` with valid YAML — verify command construction and output.
4. Write integration test for dump: with `.skill-lock.json`, fallback via
   `package.json`, empty agents directory, pre-existing-only scenario.
5. Write integration test for import: basic, partial failure (mocked), no YAML,
   invalid YAML content.
6. Write wrapper script test: `skills-add-bunx.sh` produces valid JSON,
   `skills-add-npx.sh` produces valid JSON, both non-zero on failure.
7. Harden edge cases: YAML file edit error detection, missing `bunx`/`npx`
   detection, skill-reimport idempotency, `$DOTFILES_PATH` not set fallback.
8. Run all existing `make test` — verify no regressions in existing package
   manager behavior.
9. Run `shellcheck` on all new files with no warnings.
10. Run `shfmt` on all new files with no formatting issues.

**Completion gate**: All dev scenarios from `SPEC.md` pass. `make test` green.
`dot package dump` and `dot package import` work end-to-end for skills.