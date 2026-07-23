# Progress: 12-skill-lockfile

## P1: Core infrastructure (current)
- Status: done
- Goal: YAML parser/writer, wrapper scripts producing `.skill-lock.json`, skills.sh skeleton
- Result:
  - `scripts/package/src/lib/yaml.sh` — 6 functions: `yaml::write_value`, `yaml::write_array_item`, `yaml::write_array`, `yaml::write_document`, `yaml::read_value`, `yaml::read_array`
  - `scripts/package/src/wrappers/skills-add-bunx.sh` — bunx wrapper with directory diffing and `.skill-lock.json` write
  - `scripts/package/src/wrappers/skills-add-npx.sh` — npx variant of above
  - `scripts/package/src/package_managers/skills.sh` — skeleton with `skills::title`, `skills::is_available`, `skills::setup`, no-op `skills::dump`/`skills::import`
- Gate: static_analysis ✓, lint ✓
