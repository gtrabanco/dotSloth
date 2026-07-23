# TASKS: 12-skill-lockfile

## P1 — Core infrastructure

- [ ] Create `scripts/package/src/lib/yaml.sh` with `set -euo pipefail` header and
      function declarations for `yaml::write_value`, `yaml::write_array`,
      `yaml::write_document`, `yaml::read_value`, `yaml::read_array`.
- [ ] Implement `yaml::write_value` — writes `key = "value"` lines with optional
      comment prefix (`# comment\nkey = "value"`).
- [ ] Implement `yaml::write_array` — writes `key:\n  - item\n  - item` format.
      Handle inline arrays (`key: [a, b, c]`) and block arrays (`key:\n  - item`).
- [ ] Implement `yaml::write_document` — orchestrates comment header, key-value
      pairs, and array sections. Writes to specified file path.
- [ ] Implement `yaml::read_value` — single-line parser: strips leading spaces,
      splits on first `=`, returns value (removes surrounding quotes if present).
- [ ] Implement `yaml::read_array` — parser for both inline (`[a, b, c]`) and
      block (`\n  - item`) array formats. Returns newline-separated list.
- [ ] Validate `yaml.sh` with `shfmt` and `shellcheck` — no warnings.

- [ ] Create `scripts/package/src/wrappers/skills-add-bunx.sh` with argument
      parsing: `<provider> [#<branch>] --agent <agent> [-g] [-y]`. Delegates to
      `bunx skills add` with constructed arguments.
- [ ] Implement directory diffing: snapshot `$HOME/.agents/skills/` before install,
      diff after install to detect new skill directory path.
- [ ] Implement `.skill-lock.json` write: create valid JSON with provider, branch,
      agents, command, and installed_at fields. Use `date -u +%Y-%m-%dT%H:%M:%SZ`
      for timestamp. Handle macOS `date` (no `+` format flag) and Linux.
- [ ] Create `scripts/package/src/wrappers/skills-add-npx.sh` — identical structure
      to `skills-add-bunx.sh` but delegates to `npx skills add`.
- [ ] Validate wrapper scripts with `shfmt` and `shellcheck` — no warnings.

- [ ] Create `scripts/package/src/package_managers/skills.sh` with `set -euo pipefail`
      header, source `_main.sh`, source `yaml.sh`.
- [ ] Implement `skills::setup` — no-op function (skills have no setup step).
- [ ] Implement `skills::dump` — function signature only (full implementation in P2).
- [ ] Implement `skills::import` — function signature only (full implementation in P3).
- [ ] Validate `skills.sh` with `shfmt` and `shellcheck` — no warnings.

**Completion gate**:
- [ ] `bash scripts/self/static_analysis` passes
- [ ] `bash scripts/core/lint` passes

## P2 — Dump flow

- [ ] Implement `skills::_discover_skills_with_lockfiles` — scans `$HOME/.agents/skills/`
      for directories, reads `.skill-lock.json` per directory, returns structured
      data (provider, branch, agents, command, name).
- [ ] Handle `.skill-lock.json` parse errors — skip with warning, continue scanning.
- [ ] Handle `.skill-lock.json` with missing required fields — fill defaults
      (branch: null, agents: ["unknown"]).
- [ ] Implement `skills::_discover_skills_from_package_json` — for skills without
      lockfiles, reads `package.json` from skill directory, matches dependency keys
      against `<skill-name>` or `<skill-name>#<branch>` patterns using bash regex.
- [ ] Handle `package.json` parse errors — skip with warning (no JSON library
      available, use grep/sed-based extraction).
- [ ] Handle `package.json` not present — skip with warning, log skill name.
- [ ] Implement `skills::_merge_discoveries` — primary results + fallback results,
      mark fallback entries with `discovered_by: package-json` and
      `command: unknown` or detected command.
- [ ] Emit warning for each fallback-discovered skill: "Skill X discovered via
      package.json fallback — not all install details may be accurate."
- [ ] Implement `skills::_group_by_provider` — deduplicates skills by provider name,
      groups agents across skills within a provider.
- [ ] Implement `skills::dump` — orchestrates discovery, merging, grouping, and
      calls `yaml::write_document` to produce `$DOTFILES_PATH/agents/skill-lock.yaml`.
- [ ] Handle `$HOME/.agents/` not existing — produce valid YAML with empty providers
      list and comment "No agents directory found."
- [ ] Log dump summary: "Dumped N skills (M primary, K fallback) across P provider groups."

**Completion gate**:
- [ ] `bash scripts/self/static_analysis` passes
- [ ] `bash scripts/core/lint` passes
- [ ] Manual test: `skills::dump` on populated `$HOME/.agents/skills/` produces valid YAML

## P3 — Import flow

- [ ] Implement `skills::import` — checks for `$DOTFILES_PATH/agents/skill-lock.yaml`,
      reads and parses the YAML document.
- [ ] Handle missing YAML file — fail with clear error: "No skill-lock.yaml found at
      $DOTFILES_PATH/agents/skill-lock.yaml."
- [ ] Implement `skills::_parse_yaml_document` — calls `yaml::read_value` and
      `yaml::read_array` to extract `format`, provider list, skill specs, and agent list.
- [ ] Implement `skills::_parse_yaml_raw` — fallback line-by-line parser that
      extracts raw key-value pairs for validation. Used when `yaml.sh` parsing
      fails on malformed YAML.
- [ ] Validate `format` field — must equal `skill-lock-v1` or fail with version error.
- [ ] Validate required fields per entry — provider name, skill name, command, agents.
      Skip invalid entries with warning.
- [ ] Implement `skills::_execute_single_install` — constructs command from recorded
      `command` field + provider/branch/skill, executes, captures exit code.
  > NOTE: This function must NOT have `set -euo pipefail` — per arch.md, core
  > libraries intentionally omit `set -e` so failures don't propagate to caller.
- [ ] Implement failure aggregation — track total, succeeded, failed, per-entry
      status. Log each entry's result.
- [ ] Implement `skills::_verify_install` — after install, check skill directory
      exists in `$HOME/.agents/skills/` and `.skill-lock.json` was created.
- [ ] Report summary to stdout — "Import complete: N total, S succeeded, F failed."
- [ ] Exit 0 if any success, exit 1 only if ALL installations fail.
- [ ] Handle `bunx`/`npx` not found — log error per entry, continue with next.

**Completion gate**:
- [ ] `bash scripts/self/static_analysis` passes
- [ ] `bash scripts/core/lint` passes
- [ ] Manual test: `skills::import` on valid YAML produces correct install commands

## P4 — Integration & hardening

- [ ] Register `skills` in `get_available_package_managers` (or equivalent dispatch
      function in `scripts/package/src/_main.sh`).
- [ ] Verify existing `dump`/`import` iteration picks up `skills` automatically.
- [ ] Run `dot package dump` with pre-populated skills — verify YAML structure
      matches spec schema (format, providers, skills, agents, command).
- [ ] Run `dot package import` with valid YAML — verify log output shows per-entry
      status and correct summary.
- [ ] Write integration test for dump: skills with `.skill-lock.json`, fallback via
      `package.json`, empty agents directory, pre-existing-only scenario.
- [ ] Write integration test for import: basic import, partial failure (mocked
      wrapper returns non-zero), no YAML file, invalid YAML content.
- [ ] Write wrapper script test: `skills-add-bunx.sh` produces valid JSON with
      correct fields, `skills-add-npx.sh` produces valid JSON with `npx` prefix,
      both return non-zero when underlying command fails.
- [ ] Harden: YAML file edit error detection — detect malformed lines and report
      line number.
- [ ] Harden: Missing `bunx`/`npx` detection — check for command availability before
      executing, log clear error.
- [ ] Harden: Skill reimport idempotency — `bunx`/`npx` handles it, but log
      "Already installed: skill X" when detected.
- [ ] Harden: `$DOTFILES_PATH` not set — dump uses `$HOME/.agents/` as fallback,
      import fails with clear error.
- [ ] Run `make test` — verify no regressions in existing package manager behavior.
- [ ] Run `shellcheck` on all new files — zero warnings.
- [ ] Run `shfmt` on all new files — zero formatting issues.
- [ ] Run `bash scripts/self/static_analysis` — passes.
- [ ] Run `bash scripts/core/lint` — passes.

**Completion gate**:
- [ ] `make test` passes (all existing tests + new integration tests)
- [ ] `shellcheck` — zero warnings on all new files
- [ ] `shfmt` — zero formatting issues on all new files
- [ ] `bash scripts/self/static_analysis` passes
- [ ] `bash scripts/core/lint` passes
- [ ] All dev scenarios from `SPEC.md` verified:
      - [ ] `dump:with-wrappers`
      - [ ] `dump:empty`
      - [ ] `dump:pre-existing`
      - [ ] `dump:fallback-package-json`
      - [ ] `dump:no-wrappers-no-package-json`
      - [ ] `import:basic`
      - [ ] `import:partial-failure`
      - [ ] `import:no-yaml`
      - [ ] `install:wrapper-bunx`
      - [ ] `install:wrapper-npx`