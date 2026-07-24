# 12 — skill-lockfile

> Feature specification. The doc read at the start of the workflow. Fill every
> section. Detailed phase tasks live in `PLAN.md` / `TASKS.md`, generated in
> planning from this spec.
>
> Copy this folder to `docs/features/NN-<feature-slug>/` and register the feature
> in `docs/features/ROADMAP.md` before starting.

## Goal

Add agent skill management to dotSloth's `dot package` system — dump and import
installed skills alongside existing package manager dumps. Skills installed via
`bunx skills add` or `npx skills add` are tracked via wrapper scripts that
produce a `.skill-lock.json` per skill. `dot package dump` discovers and exports
these into `$DOTFILES_PATH/agents/skill-lock.yaml`; `dot package import` reads
the YAML and reinstalls skills via the appropriate wrapper. A `package.json`
discovery fallback handles pre-existing skills without wrapper metadata.

## Branch

`feat/12-skill-lockfile`

## Size

**M** — scoped to new package manager type, wrapper scripts, dump/import flow,
and integration. Requires phased execution (P1–P4). Implements dump, import,
wrapper scripts, package.json discovery fallback, and YAML handling.

## Dependencies

None. This feature is independent of existing features (01–11 were package
manager and infrastructure additions). It extends the existing
`scripts/package/src/package_managers/` pattern.

## Context

dotSloth already supports `dot package dump` and `dot package import` for package
managers (npm, cargo, brew, pip, etc.). Skills installed via `bunx skills add`
or `npx skills add` are not captured in any dump. Users cannot reproduce their
exact skill+agent setup on a new machine. This creates a gap in the dotSloth
migration workflow — a full migration now requires manually noting which skills
were installed for which agents.

## Business goals

- Portable lockfile that reproduces exact skill+agent setup on a new machine.
- Skills dump serves as backup and migration tool between agents.
- Skills can be manually edited before import to change agent scope.

## Technical goals

- Integrate skills into existing `dot package dump/import` flow.
- Generate YAML file at `$DOTFILES_PATH/agents/skill-lock.yaml`.
- Track provider (e.g., `gtrabanco/agentic-workflow`), branch (`#claude`), skill
  name, and installed agents per skill.
- Import restores skills exactly as dumped — user can edit YAML before import.
- Wrapper scripts ensure discoverability of newly installed skills.
- `package.json` discovery fallback handles pre-existing skills without wrappers.

## Scope

### In scope

- **Wrapper scripts**: `skills-add-bunx.sh` and `skills-add-npx.sh` that wrap
  `bunx skills add` / `npx skills add` and produce `.skill-lock.json` in the
  installed skill directory, recording provider, branch, and agents.
- **Dump flow**: `skills::dump` discovers skills via two mechanisms:
  - **Primary**: scans `$HOME/.agents/skills/` for `.skill-lock.json` files
  - **Fallback**: for skills without `.skill-lock.json`, reads
    `package.json` dependencies to detect provider/branch
- **Import flow**: `skills::import` reads YAML and reinstalls skills per agent
  using the recorded command.
- **YAML parser/writer** (`yaml.sh`): minimal YAML handling for the lockfile
  schema (flat key-value, nested arrays, no external deps).
- **New package manager**: `skills.sh` implementing the standard interface.
- **New directory**: `$DOTFILES_PATH/agents/` as a dotSloth-managed directory.

### Out of scope / non-goals

- Auto-detection of which `bunx` or `npx` binary is available (the wrapper is
  explicitly chosen by the user).
- Skill removal/updates (only dump and import).
- Support for non-agentic-workflow skill providers until a future need is
  confirmed (the format supports multi-provider; the scripts require provider
  explicitly).
- Interactive skill picker (no fzf integration for skills).
- `dot package update` for skills (no-op; skills are external).
- Detecting or scanning pre-existing skills installed without wrappers as the
  primary mechanism (the package.json fallback is a best-effort supplement).

## Architecture impact

- **New package manager wrapper**: `scripts/package/src/package_managers/skills.sh`
  implementing the standard interface: `dump`, `import`.
- **New wrapper scripts**:
  `scripts/package/src/wrappers/skills-add-bunx.sh` and
  `scripts/package/src/wrappers/skills-add-npx.sh` — invoked instead of raw
  `bunx skills add` / `npx skills add`. After successful install, creates
  `.skill-lock.json` in the installed skill directory.
- **New dump file path**: `$DOTFILES_PATH/agents/skill-lock.yaml`.
- **New library dependency**: `yaml.sh` — minimal YAML reader/writer. Since
  dotSloth has no external YAML dependencies and must remain POSIX bash,
  implement a lightweight `yaml::write_*` and `yaml::read_*` set covering only
  the flat key-value and nested array structures needed.
- The `$DOTFILES_PATH/agents/` directory becomes a new top-level dotSloth-managed
  directory alongside `scripts/`, `dotfiles_template/`, `shell/`, `symlinks/`.

**Invariants the implementation must hold**:
- Core libraries must not depend on context scripts (same as all features).
- `skills.sh` must source `_main.sh` first (same as all package manager wrappers).
- All scripts use `set -euo pipefail` (mandatory per workflow conventions).
- The wrapper scripts must be POSIX-compatible bash (tested on macOS default
  bash 3.2 and Linux).
- The YAML output must be human-editable (no smart quotes, no auto-numbering,
  consistent indentation).
- The dump/import flow must not affect existing package manager dump/import
  (the existing `dump`/`import` scripts iterate over
  `package::get_available_package_managers`; `skills` will be registered there).

## Design

### Data structure — `.skill-lock.json` (per-skill metadata)

Written by wrapper scripts after successful install:

```json
{
  "provider": "gtrabanco/agentic-workflow",
  "branch": "claude",
  "agents": ["claude-code"],
  "command": "bunx skills add",
  "installed_at": "2026-07-23T12:00:00Z"
}
```

- `provider`: repo path (e.g., `gtrabanco/agentic-workflow`).
- `branch`: branch name without `#` prefix (null if no branch specified).
- `agents`: list of agent names the skill was installed for.
- `command`: the install command prefix (`bunx skills add` or `npx skills add`).
- `installed_at`: ISO 8601 timestamp of install.

### Data structure — `skill-lock.yaml` (dump file)

```yaml
# Agent skills lockfile — generated by dot package dump
# Edit this file before running `dot package import` to change agent scope
format: skill-lock-v1
providers:
  - name: gtrabanco/agentic-workflow
    skills:
      - name: design-feature
        command: bunx skills add
        agents: [claude-code, opencode]
      - name: trailmark
        command: bunx skills add
        agents: [claude-code]
  - name: gtrabanco/agentic-workflow#claude
    skills:
      - name: design-feature
        command: bunx skills add
        agents: [claude-code]
```

- `format`: schema version for future evolution.
- `providers[].name`: provider identifier (repo path with optional `#branch` suffix).
- `providers[].skills[].name`: skill directory name.
- `providers[].skills[].command`: the install command prefix.
- `providers[].skills[].agents`: list of agent names.

### Discovery and install flow

**Wrapper scripts** (`skills-add-bunx.sh` / `skills-add-npx.sh`):

1. Accept arguments: `<provider> [#<branch>] --agent <agent> [-g] [-y]`.
2. Delegate to `bunx skills add` or `npx skills add` with the same arguments.
3. On success, detect the installed skill directory (scan
   `$HOME/.agents/skills/` for new directories).
4. Write `.skill-lock.json` in the skill directory.

**Dump flow** (`skills::dump`):

1. Scan `$HOME/.agents/skills/` for directories.
2. **Primary discovery**: for each directory, check for `.skill-lock.json`. If
   present, read provider, branch, agents, command.
3. **Fallback discovery**: for directories without `.skill-lock.json`, check for
   `package.json`. If present, scan dependencies for keys matching
   `*/<skill-name>` or `*/<skill-name>#*` to extract provider info.
4. Group by provider name. For skills discovered via fallback, record
   `command: <detected>` or `command: unknown` and emit a warning.
5. Write YAML to `$DOTFILES_PATH/agents/skill-lock.yaml`.
6. Log the number of skills dumped (primary + fallback counts).

**Import flow** (`skills::import`):

1. Check if `$DOTFILES_PATH/agents/skill-lock.yaml` exists.
2. Parse the YAML file.
3. For each provider/skill/agent combination:
   a. Construct the install command from the recorded `command` field.
   b. Execute the command.
   c. Log success or failure.
4. Report summary: total installed, total succeeded, total failed.
5. Fail (non-zero exit) only if ALL installations fail; partial failures log
   warnings but succeed.

### Error and edge states

| State | Behavior |
|-------|----------|
| No `$HOME/.agents/` directory | Dump produces empty providers list; import fails with clear error. |
| Pre-existing skills without `.skill-lock.json` | Dump scans `package.json` as fallback; if no `package.json`, skip with warning. |
| YAML file edit error (invalid YAML) | Import fails with clear error pointing to the line/field. |
| Missing `bunx`/`npx` on target machine | The recorded error during import; user must install the missing tool. |
| Missing provider/branch (invalid URL) | Import fails for that specific skill entry with error; other skills continue. |
| Agent argument not available | Skills CLI returns error; import logs failure for that entry, continues. |
| Skill already installed (re-import) | `bunx`/`npx` handles idempotency; log as already-installed. |
| `$DOTFILES_PATH` not set | Dump uses `$HOME/.agents/` as fallback; import fails if YAML path is invalid. |

## Decisions to confirm

| Decision | Choice | Rationale |
|----------|--------|----------|
| File format | YAML (`skill-lock.yaml`) | Human-editable, matches existing `Brewfile` pattern, supports structured nested data. |
| File name | `skill-lock.yaml` | `lock` suffix signals machine-generated (like `lockfile`, `Brewfile`). |
| Primary discovery | `.skill-lock.json` from wrapper scripts | Unambiguous — records exactly what command was used at install time. |
| Fallback discovery | `package.json` dependencies | Covers pre-existing skills without wrappers; best-effort, not required. |
| Import verification | Check that skill directory exists after install | Basic verification — confirm the `.skill-lock.json` was created by the wrapper. |
| YAML format version | Include `format: skill-lock-v1` in header | Future-proofs against schema changes. |
| `dot package` integration | Register `skills` as a package manager type | Extends existing `dump`/`import` loop. |
| Pre-existing skills | Warn and offer package.json fallback | Cannot retroactively create `.skill-lock.json` without re-installing. |
| Install scope detection | Detect new directories in `$HOME/.agents/skills/` after install | The wrapper scripts diff the directory before/after install. |

## Acceptance criteria

- [ ] `dot package dump` generates `$DOTFILES_PATH/agents/skill-lock.yaml` with
      all discovered skills (those with `.skill-lock.json`, plus `package.json`
      fallback for pre-existing skills).
- [ ] YAML file contains provider name, skill name, command, and agents list.
- [ ] `dot package import` reads the YAML and invokes the recorded install
      command for each provider/skill/agent combination.
- [ ] Import reports success/failure per skill installation with clear log messages.
- [ ] Install wrapper scripts (`skills-add-bunx`, `skills-add-npx`) create
      `.skill-lock.json` on successful install with correct fields.
- [ ] Pre-existing skills without `.skill-lock.json` produce a warning during dump
      (not an error); skills with `package.json` are discovered via fallback.
- [ ] Partial import failures report successes and warnings but do not abort.
- [ ] Existing package manager dump/import flow is unaffected.
- [ ] All scripts use `set -euo pipefail` and pass `shfmt` and `shellcheck`.

## Testing requirements

- **Integration tests** for dump:
  - Run `skills::dump` with pre-populated `$HOME/.agents/skills/` containing
    skills with and without `.skill-lock.json`.
  - Verify YAML structure: correct provider grouping, skill names, agents arrays,
    command values.
  - Verify empty agents directory produces valid YAML with empty providers list.
  - Verify fallback discovery via `package.json` for pre-existing skills.
- **Integration tests** for import:
  - Run `skills::import` with a YAML file containing valid entries.
  - Verify install commands are constructed correctly.
  - Verify that simulated failures (mocked wrapper) report per-entry errors
    without aborting the import.
- **Edge case tests**:
  - Import with non-existent YAML file (should prompt or fail gracefully).
  - Import with invalid YAML content (should fail with parse error).
  - Import on machine with neither `bunx` nor `npx` (should fail for all entries).
  - Import with a provider that returns non-zero exit code (should log failure, continue).
  - Dump with skills that have no `.skill-lock.json` and no `package.json`.
- **Wrapper script tests**:
  - `skills-add-bunx.sh` produces valid `.skill-lock.json` with correct provider,
    branch, agents, and command fields.
  - `skills-add-npx.sh` produces valid `.skill-lock.json` with `npx` command prefix.
  - Both scripts return non-zero when the underlying `bunx/npx` command fails.

## Dev scenarios

| Scenario | Reproduces | Mechanism it drives |
|---|---|---|
| `dump:with-wrappers` | Machine with skills installed via wrapper | `dot package dump` |
| `dump:empty` | Machine with `$HOME/.agents/skills/` but no `.skill-lock.json` files | `dot package dump` |
| `dump:pre-existing` | Some skills have `.skill-lock.json`, some don't | `dot package dump` |
| `dump:fallback-package-json` | Pre-existing skill with `package.json` but no wrapper | `dot package dump` |
| `dump:no-wrappers-no-package-json` | Pre-existing skill with neither | `dot package dump` |
| `import:basic` | Valid `skill-lock.yaml` on a fresh machine | `dot package import` |
| `import:partial-failure` | YAML has one invalid provider path | `dot package import` |
| `import:no-yaml` | No `skill-lock.yaml` exists | `dot package import` |
| `install:wrapper-bunx` | New skill installed via `skills-add-bunx` | Install wrapper |
| `install:wrapper-npx` | New skill installed via `skills-add-npx` | Install wrapper |

## Phases

- **P1 — Core infrastructure**: YAML parser/writer (`yaml.sh`), wrapper scripts
  (`skills-add-bunx`, `skills-add-npx`), `.skill-lock.json` schema, `skills.sh`
  package manager skeleton with `dump` and `import` function signatures.
- **P2 — Dump flow**: `skills::dump` implementation — primary discovery (`.skill-lock.json`),
  fallback discovery (`package.json`), group by provider, write YAML, log counts.
- **P3 — Import flow**: `skills::import` implementation — parse YAML, construct
  commands, execute, verify post-install, report summary.
- **P4 — Integration & hardening**: Register `skills` in
  `get_available_package_managers`, integration tests for all dev scenarios,
  wrapper documentation, shellcheck/shfmt gate, edge case hardening.

## Deploy & rollback

n/a — this is a feature addition, not a deploy. Merging to `main` is sufficient.
Rollback via revert PR if issues are found post-merge.

## Open questions / risks

- **YAML generation without external deps**: dotSloth has no YAML library. A small
  bespoke implementation is needed (~200 lines for write/read operations covering
  flat key-value and nested arrays). Risk: edge case YAML parsing (escaped values,
  multi-line strings) — these are not needed for the current schema (all values
  are simple strings, arrays, and flat key-value pairs).
- **Pre-existing skills need fallback**: Skills installed before this feature exist
  without `.skill-lock.json`. The `package.json` fallback handles most cases, but
  skills without `package.json` will be silently skipped with a warning. Document
  this as a known limitation.
- **`$HOME/.agents/skills/` scan reliability**: The wrapper scripts detect new
  skill directories by diffing before/after install. This may mis-identify if the
  user runs other `.agents` operations concurrently. Acceptable risk for
  single-user workstations.
- **Dual discovery mechanisms**: Having both `.skill-lock.json` and `package.json`
  discovery adds complexity. The primary/fallback distinction must be clearly
  documented and tested to avoid confusion.

## Deliverables

- `scripts/package/src/package_managers/skills.sh` — new package manager script
  (dump, import).
- `scripts/package/src/wrappers/skills-add-bunx.sh` — install wrapper for bunx.
- `scripts/package/src/wrappers/skills-add-npx.sh` — install wrapper for npx.
- `scripts/package/src/lib/yaml.sh` — minimal YAML parser/writer.
- `$DOTFILES_PATH/agents/skill-lock.yaml` generation and parsing.
- Integration tests for dump, import, wrappers, and fallback discovery.
- Documentation for wrapper usage in existing README or a dedicated section.

## Post-merge next feature

Feature 13 — Potential: extend skills dump to support the agentic-workflow's own
skill registry file (e.g., `.agents/skills.json` if the workflow produces one —
depends on whether the workflow emits a consolidated listing).

## Design status: designed

Capability closure satisfied. All rubric slots filled or explicitly `n/a`.
Feature is sized **M** — phased execution required (P1–P4).