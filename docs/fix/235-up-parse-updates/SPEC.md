# Fix #235 — `up` command fails to parse updates

## Issue
[#235](https://github.com/gtrabanco/dotSloth/issues/235)

## Root Causes

### Bug 1 (Critical): dnf.sh variable mix-up — wrong source variable + missing echo
**File:** `scripts/package/src/package_managers/dnf.sh:57-58`
**Problem:**
- Line 57: `outdated_app_version` reads from `outdated_app_info` (empty at this
  point) instead of `outdated_app_full_info`.
- Line 58: `outdated_app_info` tries to execute `outdated_app_full_info` as a
  command (bare invocation without `echo`), which fails silently under
  `set -euo pipefail` or produces garbage.

**Fix:**
```bash
outdated_app_version="$(echo "$outdated_app_full_info" | head -n 5 | tail -n 1)"
outdated_app_info="$(echo "$outdated_app_full_info" | head -n 9 | tail -n 1)"
outdated_app_url="$(echo "$outdated_app_full_info" | head -n 10 | tail -n 1)"
```

### Bug 2 (Medium): dnf.sh unquoted command substitution in for loop
**File:** `scripts/package/src/package_managers/dnf.sh:53`
**Code:** `for outdated_app in $(dnf::outdated_app); do`
**Problem:** Unquoted `$(...)` causes word splitting on package names with
spaces or special characters.

**Fix:** Use `readarray -t` + indexed loop, matching the pattern used in
brew.sh and mas.sh:
```bash
readarray -t outdated_apps < <(dnf::outdated_app)
for outdated_app in "${outdated_apps[@]}"; do
```

### Bug 3 (Medium): npm.sh `outdated` variable not declared local
**File:** `scripts/package/src/package_managers/npm.sh:31`
**Code:** `outdated=$(npm -g outdated | tail -n +2)`
**Problem:** `outdated` is not declared `local`, leaking into the global scope.
Under `set -u` in callers, this can cause unexpected behavior.

**Fix:** Add `local` prefix.

### Bug 4 (Medium): pip.sh `outdated` variable not declared local
**File:** `scripts/package/src/package_managers/pip.sh:37`
**Same problem and fix as Bug 3.**

### Bug 5 (Medium): gem.sh `outdated` variable not declared local
**File:** `scripts/package/src/package_managers/gem.sh:50`
**Same problem and fix as Bug 3.**

### Bug 6 (Critical): apt.sh missing install flag and -y
**File:** `scripts/package/src/package_managers/apt.sh:66`
**Code:** `sudo apt-get --only-upgrade "$outdated_app" | log::file "..."`
**Problem:** Missing `install` subcommand and `-y` flag. `apt-get --only-upgrade
<package>` is not a valid invocation — it needs `install` to know what to do.
Without `-y`, apt-get will hang waiting for user confirmation.

**Fix:** `sudo apt-get -y --only-upgrade install "$outdated_app" | log::file "..."`

### Bug 7 (Critical): composer.sh `jq-cr` should be `jq -cr`
**File:** `scripts/package/src/package_managers/composer.sh:22`
**Code:** `echo "$outdated" | jq-cr '.installed | .[]' | ...`
**Problem:** `jq-cr` is not a valid command. It should be `jq -cr` (compact +
raw output flags). This causes the composer update_all to fail entirely with
"command not found".

**Fix:** `echo "$outdated" | jq -cr '.installed | .[]' | ...`

### Bug 8 (Low): bin/up `package_title` not declared local
**File:** `bin/up:46`
**Code:** `package_title="${package_manager}_title"`
**Problem:** `package_title` is not declared `local` in the loop, leaking
between iterations. Not a functional bug today but violates hygiene and can
cause issues under `set -u`.

**Fix:** Add `local` prefix.

## Scope
- `bin/up` — Bug 8
- `scripts/package/src/package_managers/dnf.sh` — Bugs 1, 2
- `scripts/package/src/package_managers/npm.sh` — Bug 3
- `scripts/package/src/package_managers/pip.sh` — Bug 4
- `scripts/package/src/package_managers/gem.sh` — Bug 5
- `scripts/package/src/package_managers/apt.sh` — Bug 6
- `scripts/package/src/package_managers/composer.sh` — Bug 7

## Verification
```bash
export PROJECT_ROOT=/Users/gtrabanco/MyProjects/dotSloth
export SLOTH_PATH=/Users/gtrabanco/MyProjects/dotSloth
export DOTLY_PATH=/Users/gtrabanco/MyProjects/dotSloth
bash scripts/self/static_analysis
bash scripts/self/lint
make test
```

## Size: M
