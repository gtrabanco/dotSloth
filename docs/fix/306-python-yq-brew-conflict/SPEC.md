# fix/306-python-yq-brew-conflict

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Repair `python-yq::install` so it succeeds on macOS hosts where the Go `yq`
formula (mikefarah/yq) is already installed via Homebrew. The current recipe
calls `brew install python-yq` directly, which Homebrew rejects with a formula
conflict (both ship a `yq` executable), aborting the symlinks step and cascading
into the zim install. This cannot wait for a feature cycle because it breaks the
installer on the current macOS GitHub Actions runner image, which now ships the
Go `yq` preinstalled.

## Issue

`#306` — tracked issue. Required. The PR must close it.

## Branch

`fix/306-python-yq-brew-conflict`

## Root cause

`scripts/package/src/recipes/python-yq.sh:27` (pre-fix) runs
`brew install python-yq` while the Go `yq` formula is linked. Homebrew refuses:

```
Cannot install python-yq because conflicting formulae are installed.
  yq: because both install `yq` executables
Please `brew unlink yq` before continuing.
```

The pip fallback (`scripts/package/src/recipes/python-yq.sh:36`,
`python3 -m pip install --user --no-cache-dir yq`) then trips PEP 668
(`externally-managed-environment`) on the externally-managed macOS Python, so
both install paths fail and the recipe returns 1. The symlinks step aborts and
zim cannot source `~/.zimrc`.

Evidence: CI run 28825710882, job `🚀 Build (macos-latest)` —
https://github.com/gtrabanco/dotSloth/actions/runs/28825710882/job/85488175049

The project requires kislyuk/yq (python-yq) specifically — see
`python-yq::is_installed` (`yq --help | grep kislyuk`) and the `yq -r '.'` usage
in `scripts/core/src/yaml.sh` — so replacing the active `yq` is intended, not a
side effect.

## Scope

### In scope

`scripts/package/src/recipes/python-yq.sh` only: unlink the Go `yq` formula
before `brew install python-yq` and `brew reinstall python-yq`.

### Out of scope

- PEP 668 in the pip fallback path — only reached when brew is absent; the brew
  path now succeeds on macOS, so the pip fallback is not exercised in CI. A
  separate issue could add `--break-system-packages` handling if needed.
- Choosing between Go `yq` and python-yq globally — out of scope; the project
  already mandates python-yq.

## Impact

- Modules/files touched: `scripts/package/src/recipes/python-yq.sh`.
- Blast radius: if the unlink is wrong, `brew install python-yq` could still
  fail or the user's Go `yq` could be left unlinked. The unlink is guarded by
  `brew list --versions yq` (only fires when the Go formula is installed) and is
  reversible with `brew link yq`. No change on Linux/FreeBSD or on macOS without
  the Go `yq`.
- Detection lead time: immediate — CI `🚀 Build (macos-latest)` surfaces it on
  the next run.

## Rules that must never be violated

- Cross-platform guards: brew is only invoked through `platform::command_exists
  brew` (preserved).
- Shell compatibility: no bashisms; `> /dev/null 2>&1`, `|| true`, and the `if`
  guard are POSIX-compatible and safe on macOS bash 3.2.
- No new dependencies.
- Recipe namespace convention: helper is `python-yq::_unlink_conflicting_yq`.

## Risks

- Operational: a user who intentionally uses the Go `yq` will find it unlinked
  after running the installer. Mitigation: the change only runs during
  `python-yq::install`, is reversible (`brew link yq`), and the project
  mandates python-yq anyway.
- Security: n/a — no privilege change, no network, no secret handling.
- Compliance: n/a.

## Acceptance criteria

- [x] `./scripts/core/lint` green (shfmt) — verified with shfmt v3.11.0,
      `-ln bash -sr -ci -i 2 -d` returns no diff.
- [x] `./scripts/core/static_analysis` green (shellcheck) — verified with
      shellcheck v0.10.0, `-s bash -S warning -e SC1090 -e SC2010 -e SC2154`
      returns clean.
- [ ] `python-yq::install` succeeds on a macOS runner with the Go `yq` formula
      preinstalled — CI `🚀 Build (macos-latest)` passes on the fix PR. (Pending
      CI run on the PR.)

## Rollback

Revert the commit. No data-side cleanup: `brew unlink yq` only removes
Homebrew symlinks for the Go `yq`, restored with `brew link yq`. python-yq, once
installed, is unaffected by a revert.

## Effort

XS — single-file, ~10-line additive change with a guarded, reversible helper.
