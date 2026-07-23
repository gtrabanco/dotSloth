# Progress: 12-skill-lockfile

## P1: Core infrastructure
- Status: done
- Goal: YAML parser/writer, wrapper scripts producing `.skill-lock.json`, skills.sh skeleton
- Result:
  - `scripts/package/src/lib/yaml.sh` — 6 functions: `yaml::write_value`, `yaml::write_array_item`, `yaml::write_array`, `yaml::write_document`, `yaml::read_value`, `yaml::read_array`
  - `scripts/package/src/wrappers/skills-add-bunx.sh` — bunx wrapper with directory diffing and `.skill-lock.json` write
  - `scripts/package/src/wrappers/skills-add-npx.sh` — npx variant of above
  - `scripts/package/src/package_managers/skills.sh` — skeleton with `skills::title`, `skills::is_available`, `skills::setup`, no-op `skills::dump`/`skills::import`
- Gate: static_analysis ✓, lint ✓

## P2: Dump flow (current)
- Status: done
- Goal: Skills discovery (`.skill-lock.json` primary, `package.json` fallback), provider grouping, YAML output
- Result:
  - `skills::_discover_skills_with_lockfiles` — scans `$HOME/.agents/skills/` for `.skill-lock.json`, extracts provider/branch/agents/command
  - `skills::_discover_skills_from_package_json` — fallback for skills without lockfiles, reads `package.json` name/branch
  - `skills::dump` — orchestrates discovery → merge → group-by-provider → `yaml::write_document` to `$DOTFILES_PATH/agents/skill-lock.yaml`
  - Fixes to `yaml.sh`: `yaml::write_value` outputs bare `key:` for empty values; `yaml::write_array` reads indent from last positional arg
- Gate: static_analysis ✓, lint ✓
