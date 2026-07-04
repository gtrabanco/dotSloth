# Fix #234 — Restorer broken

## Issue
[#234](https://github.com/gtrabanco/dotSloth/issues/234)

## Root Causes

### Bug 1 (Critical): `create_dotfiles_dir` function does not exist
**File:** `restorer:327`
**Code:** `[[ "${PROMPT_REPLY:-Y}" =~ ^[Yy] ]] && create_dotfiles_dir "$DOTFILES_PATH"`
**Problem:** The function `create_dotfiles_dir` is called but never defined. The
defined function is `backup_dotfiles_dir` (line 97), which backs up an existing
dotfiles directory. When the user answers "Y" to the backup prompt, the script
crashes with "command not found" under `set -euo pipefail`.

**Fix:** Replace `create_dotfiles_dir` with `backup_dotfiles_dir`.

### Bug 2 (Critical): `IS_ICLOUD_DOTFILES` never set to true
**File:** `restorer:55, 394-404, 450`
**Problem:** `IS_ICLOUD_DOTFILES` is initialized to `false` at line 55 but is
never set to `true` inside the iCloud option block (lines 394-404). The git
clone block at line 450 (`if ${IS_ICLOUD_DOTFILES:-false}`) never executes,
meaning the restorer skips cloning dotfiles entirely for all git-based options
(GitHub, Keybase, Other Git), jumping directly to submodule update without
having cloned the dotfiles repository first.

The original intent of the `IS_ICLOUD_DOTFILES` guard was to skip git clone for
iCloud (which uses `ln -s` instead). The logic should be inverted: clone for
all git-based sources, skip for iCloud.

**Fix:** Remove the `IS_ICLOUD_DOTFILES` guard entirely. The iCloud path
already creates a symlink and does not set `GIT_URL`, so it naturally skips the
clone block (which requires `GIT_URL`). Alternatively, set
`IS_ICLOUD_DOTFILES=true` inside the iCloud case. The simplest correct fix is
to invert the condition: `if ! ${IS_ICLOUD_DOTFILES:-false}; then` — clone when
NOT iCloud. This matches the original intent.

### Bug 3 (Medium): `output::yesno` called before sloth is loaded
**File:** `restorer:246-248`
**Problem:** The restorer is a standalone script that does not load sloth
libraries (`scripts/core/src/_main.sh`) until line 504 (`dot core install`).
Lines 246-248 call `output::yesno`, a function from `output.sh` that is not
available at that point. If the symlinks backup prompt branch is reached (when
`DOTLY_ENV` is not CI, `never_backup` is false, and `always_backup` is false),
the script crashes with "command not found".

**Fix:** Replace `output::yesno` calls with the restorer's own `_q` function
(line 78), which is a simple `read -rp` wrapper already defined in the script.
The logic needs adaptation: `_q` returns the answer in a variable, while
`output::yesno` returns 0/1. Use `_q` + `[[ =~ ^[Yy] ]]` pattern.

### Bug 4 (Low): Escaped space in ICLOUD_PATH
**File:** `restorer:54`
**Code:** `ICLOUD_PATH="$HOME/Library/Mobile\\ Documents/com~apple~CloudDocs/"`
**Problem:** The path contains a literal backslash-space (`\\ `) inside double
quotes. In double quotes, `\\` is a literal backslash, so the path becomes
`$HOME/Library/Mobile\ Documents/com~apple~CloudDocs/` with a literal backslash
in the directory name. The correct path on macOS has a space, not a backslash.

**Fix:** Remove the extra backslash: `ICLOUD_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/"`

## Scope
- `restorer` — Bugs 1, 2, 3, 4

## Verification
```bash
export PROJECT_ROOT=/Users/gtrabanco/MyProjects/dotSloth
export SLOTH_PATH=/Users/gtrabanco/MyProjects/dotSloth
export DOTLY_PATH=/Users/gtrabanco/MyProjects/dotSloth
bash scripts/self/static_analysis
bash scripts/self/lint
make test
```

## Size: S
