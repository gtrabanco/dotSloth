# AUDIT: upstream changes (CodelyTV/dotly)

## Summary
69 common files, 50 with differences. Most diffs are structural (dotSloth reorganized core modules into `src/`). A handful of upstream improvements are safe to cherry-pick.

## Safe to Cherry-Pick

### .github/workflows/ci.yml
- **Upstream adds:** `paths-ignore` for docs, `fail-fast: false`, shell speed tests, better debugging
- **Why:** CI improvements reduce noise and add performance tracking
- **Impact:** ~30 lines added (repo path and OS versions need adaptation)

## Already Better in dotSloth (No Sync Needed)

### .github/workflows/ci.yml
- dotSloth already has: `paths-ignore`, `fail-fast: false`, speed tests, `always()` debug
- Upstream only has `failure()` debug (dotSloth's `always()` is better)
- **Verdict:** dotSloth is BETTER — no sync needed

## Already Better in dotSloth (No Sync Needed)

### bin/pbcopy, bin/pbpaste
- dotSloth already uses `command -v` detection (more portable than upstream's `uname` checks)
- **Verdict:** dotSloth is BETTER — no sync needed

### scripts/package/src/package_managers/gem.sh
- dotSloth (84 lines) has MORE functions than upstream (26 lines): `gem::title()`, `gem::is_available()`, `gem::install()`, `gem::is_installed()`, `gem::package_exists()`, `gem::self_update()`, `gem::cleanup()`
- Upstream only has `gem::is_macos_default()` and `gem::update_all()`
- **Verdict:** dotSloth is BETTER — no sync needed

### scripts/package/src/package_managers/npm.sh
- dotSloth (94 lines) has MORE functions than upstream (26 lines): `npm::title()`, `npm::is_available()`, `npm::install()`, `npm::is_installed()`, `npm::uninstall()`, `npm::package_exists()`, `npm::self_update()`, `npm::dump()`, `npm::import()`
- Upstream only has `npm::update_all()`
- **Verdict:** dotSloth is BETTER — no sync needed

## Do NOT Sync (Structural / dotSloth-specific)

| File | Reason |
|------|--------|
| bin/dot | Heavily customized (Homebrew patch, SLOTH_PATH detection) |
| scripts/core/_main.sh | Different structure (upstream sources flat files, dotSloth uses src/) |
| scripts/core/short_pwd | Different approach (dotSloth uses zsh, upstream uses bash) |
| restorer | Completely rewritten for dotSloth |
| installer | Completely rewritten for dotSloth |
| dotfiles_template/ | DotSloth-specific content |
| shell/bash/completions/_dot | DotSloth-specific completion |
| shell/bash/themes/codely.sh | DotSloth-specific theme |
| shell/zsh/themes/prompt_*_setup | DotSloth-specific themes |
| README.md | Different documentation |
| LICENSE | Different (MIT vs Apache) |

## Not Worth Syncing (Cosmetic / Minimal)

| File | Lines | Reason |
|------|-------|--------|
| .editorconfig | 33 | Formatting differences only |
| .gitignore | 1 | Trivial |
| dotfiles_template/.gitignore | 14 | Template, not runtime |
| dotfiles_template/shell/.inputrc | 1 | Trivial |
| dotfiles_template/shell/bash/.bash_profile | 1 | Trivial |
| dotfiles_template/shell/zsh/.zimrc | 1 | Trivial |
| dotfiles_template/shell/zsh/.zlogin | 2 | Trivial |
| shell/zsh/bindings/dot.zsh | 2 | Trivial |
| shell/zsh/themes/prompt_codelytv_setup | 2 | Trivial |
