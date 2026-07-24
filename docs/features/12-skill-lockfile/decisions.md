# Decisions: 12-skill-lockfile

## D1: Library files omit `set -euo pipefail`
- `yaml.sh` and `skills.sh` are sourced libraries, not standalone scripts.
- Following the convention of all existing core libraries (`dot.sh`, `output.sh`, `log.sh`) and package managers (`brew.sh`, etc.), they do NOT use `set -euo pipefail`.
- Only standalone entry-point scripts (e.g., wrapper scripts in `wrappers/`) use `set -euo pipefail`.
- Rationale: `set -e` in a sourced library would cause the parent script to exit on any command failure, violating the project's error-handling pattern.

## D2: `skills.sh` does not source `_main.sh` or `yaml.sh` in P1
- `skills.sh` is loaded via `dot::load_library` (which sources it in the parent script's context where `_main.sh` is already loaded).
- `yaml.sh` will be sourced in P2 when `skills::dump` actually needs it.
- Following the convention of all other package managers (`brew.sh`, etc.) which do not source `_main.sh`.

## D3: YAML format uses `key: value` (colon-space) not `key = value`
- `yaml::read_value` splits on `: ` (colon-space) and `yaml::write_value` uses `key: value` format.
- This is standard YAML, not the `.gitconfig`-style `key = value` format initially described in TASKS.
- The TASKS prose was updated to reflect the correct format.
