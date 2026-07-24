# TASKS: 12-skill-lockfile

## P1 — Core infrastructure

- [x] Create `scripts/package/src/lib/yaml.sh` with
      function declarations for `yaml::write_value`, `yaml::write_array_item`,
      `yaml::write_array`, `yaml::write_document`, `yaml::read_value`,
      `yaml::read_array`. (Library — no `set -euo pipefail`, per sourced-lib convention.)
- [x] Implement `yaml::write_value` — writes `key = "value"` lines with optional
      comment prefix (`# comment\nkey = "value"`).
- [x] Implement `yaml::write_array` — writes `key:\n  - item\n  - item` format.
      Handle inline arrays (`key: [a, b, c]`) and block arrays (`key:\n  - item`).
- [x] Implement `yaml::write_document` — orchestrates comment header, key-value
      pairs, and array sections. Writes to specified file path.
- [x] Implement `yaml::read_value` — single-line parser: strips leading spaces,
      splits on first `:`, returns value (removes surrounding quotes if present).
- [x] Implement `yaml::read_array` — parser for both inline (`[a, b, c]`) and
      block (`\n  - item`) array formats. Returns newline-separated list.
- [x] Validate `yaml.sh` with `shfmt` and `shellcheck` — no warnings.

- [x] Create `scripts/package/src/wrappers/skills-add-bunx.sh` with argument
      parsing: `<provider> [#<branch>] --agent <agent> [-g] [-y]`. Delegates to
      `bunx skills add` with constructed arguments.
- [x] Implement directory diffing: snapshot `$HOME/.agents/skills/` before install,
      diff after install to detect new skill directory path.
- [x] Implement `.skill-lock.json` write: create valid JSON with provider, branch,
      agents, command, and installed_at fields. Use `date -u +%Y-%m-%dT%H:%M:%SZ`
      for timestamp. Handle macOS `date` (no `+` format flag) and Linux.
- [x] Create `scripts/package/src/wrappers/skills-add-npx.sh` — identical structure
      to `skills-add-bunx.sh` but delegates to `npx skills add`.
- [x] Validate wrapper scripts with `shfmt` and `shellcheck` — no warnings.

- [x] Create `scripts/package/src/package_managers/skills.sh` with
      `skills::title`, `skills::is_available`, `skills::setup`, and no-op stubs
      for `skills::dump` and `skills::import`. (Sourced library — follows brew.sh
      convention, no `set -euo pipefail` or `source _main.sh`.)
- [x] Implement `skills::setup` — no-op function (skills have no setup step).
- [x] Implement `skills::dump` — function signature only (full implementation in P2).
- [x] Implement `skills::import` — function signature only (full implementation in P3).
- [x] Validate `skills.sh` with `shfmt` and `shellcheck` — no warnings.

**Completion gate**:
- [x] `bash scripts/self/static_analysis` passes
- [x] `bash scripts/core/lint` passes

## P2 — Dump flow

- [x] Implement `skills::_discover_skills_with_lockfiles` — scans `$HOME/.agents/skills/`
      for directories, reads `.skill-lock.json` per directory, returns structured
      data (provider, branch, agents, command, name).
- [x] Handle `.skill-lock.json` parse errors — skip with warning, continue scanning.
- [x] Handle `.skill-lock.json` with missing required fields — fill defaults
      (branch: null, agents: ["unknown"]).
- [x] Implement `skills::_discover_skills_from_package_json` — for skills without
      lockfiles, reads `package.json` from skill directory, matches dependency keys
      against `<skill-name>` or `<skill-name>#<branch>` patterns using bash regex.
- [x] Handle `package.json` parse errors — skip with warning (no JSON library
      available, use grep/sed-based extraction).
- [x] Handle `package.json` not present — skip with warning, log skill name.
- [x] Implement `skills::_merge_discoveries` — primary results + fallback results,
      mark fallback entries with `discovered_by: package-json` and
      `command: unknown` or detected command.
- [x] Emit warning for each fallback-discovered skill: "Skill X discovered via
      package.json fallback — not all install details may be accurate."
- [x] Implement `skills::_group_by_provider` — deduplicates skills by provider name,
      groups agents across skills within a provider.
- [x] Implement `skills::dump` — orchestrates discovery, merging, grouping, and
      calls `yaml::write_document` to produce `$DOTFILES_PATH/agents/skill-lock.yaml`.
- [x] Handle `$HOME/.agents/` not existing — produce valid YAML with empty providers
      list and comment "No agents directory found."
- [x] Log dump summary: "Dumped N skills (M primary, K fallback) across P provider groups."

**Completion gate**:
- [x] `bash scripts/self/static_analysis` passes
- [x] `bash scripts/core/lint` passes
- [ ] Manual test: `skills::dump` on populated `$HOME/.agents/skills/` produces valid YAML

## P3 — Import flow

- [x] Implement `skills::import` — checks for `$DOTFILES_PATH/agents/skill-lock.yaml`,
      reads and parses the YAML document.
- [x] Handle missing YAML file — fail with clear error: "No skill-lock.yaml found at
      $DOTFILES_PATH/agents/skill-lock.yaml."
- [x] Implement `skills::_parse_yaml_document` — calls `yaml::read_value` and
      `yaml::read_array` to extract `format`, provider list, skill specs, and agent list.
- [x] Implement `skills::_parse_yaml_raw` — fallback line-by-line parser that
      extracts raw key-value pairs for validation. Used when `yaml.sh` parsing
      fails on malformed YAML.
- [x] Validate `format` field — must equal `skill-lock-v1` or fail with version error.
- [x] Validate required fields per entry — provider name, skill name, command, agents.
      Skip invalid entries with warning.
- [x] Implement `skills::_execute_single_install` — constructs command from recorded
      `command` field + provider/branch/skill, executes, captures exit code.
  > NOTE: This function must NOT have `set -euo pipefail` — per arch.md, core
  > libraries intentionally omit `set -e` so failures don't propagate to caller.
- [x] Implement failure aggregation — track total, succeeded, failed, per-entry
      status. Log each entry's result.
- [x] Implement `skills::_verify_install` — after install, check skill directory
      exists in `$HOME/.agents/skills/` and `.skill-lock.json` was created.
- [x] Report summary to stdout — "Import complete: N total, S succeeded, F failed."
- [x] Exit 0 if any success, exit 1 only if ALL installations fail.
- [x] Handle `bunx`/`npx` not found — log error per entry, continue with next.

**Completion gate**:
- [x] `bash scripts/self/static_analysis` passes
- [x] `bash scripts/core/lint` passes
- [ ] Manual test: `skills::import` on valid YAML produces correct install commands

## P4 — Integration & hardening

- [x] Register `skills` in `get_available_package_managers` (or equivalent dispatch
      function in `scripts/package/src/_main.sh`).
- [x] Verify existing `dump`/`import` iteration picks up `skills` automatically.
- [x] Run `dot package dump` with pre-populated skills — verify YAML structure
      matches spec schema (format, providers, skills, agents, command).
- [x] Run `dot package import` with valid YAML — verify log output shows per-entry
      status and correct summary.
- [x] Write integration test for dump: skills with `.skill-lock.json`, fallback via
      `package.json`, empty agents directory, pre-existing-only scenario.
- [x] Write integration test for import: basic import, partial failure (mocked
      wrapper returns non-zero), no YAML file, invalid YAML content.
- [x] Write wrapper script test: `skills-add-bunx.sh` produces valid JSON with
      correct fields, `skills-add-npx.sh` produces valid JSON with `npx` prefix,
      both return non-zero when underlying command fails.
- [x] Harden: YAML file edit error detection — detect malformed lines and report
      line number.
- [x] Harden: Missing `bunx`/`npx` detection — check for command availability before
      executing, log clear error.
- [x] Harden: Skill reimport idempotency — `bunx`/`npx` handles it, but log
      "Already installed: skill X" when detected.
- [x] Harden: `$DOTFILES_PATH` not set — dump uses `$HOME/.agents/` as fallback,
      import fails with clear error.
- [x] Run `make test` — verify no regressions in existing package manager behavior.
- [x] Run `shellcheck` on all new files — zero warnings.
- [x] Run `shfmt` on all new files — zero formatting issues.
- [x] Run `bash scripts/self/static_analysis` — passes.
- [x] Run `bash scripts/core/lint` — passes.

**Completion gate**:
- [x] `make test` passes (all existing tests + new integration tests)
- [x] `shellcheck` — zero warnings on all new files
- [x] `shfmt` — zero formatting issues on all new files
- [x] `bash scripts/self/static_analysis` passes
- [x] `bash scripts/core/lint` passes
- [x] All dev scenarios from `SPEC.md` verified:
      - [x] `dump:with-wrappers`
      - [x] `dump:empty`
      - [x] `dump:pre-existing`
      - [x] `dump:fallback-package-json`
      - [x] `dump:no-wrappers-no-package-json`
      - [x] `import:basic`
      - [x] `import:partial-failure`
      - [x] `import:no-yaml`
      - [x] `install:wrapper-bunx`
      - [x] `install:wrapper-npx`