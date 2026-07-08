<p align="center">
  <a href="https://github.com/gtrabanco/dotSloth">
    <img src="sloth.svg" alt="Sloth Logo" width="256px" height="256px" />
  </a>
</p>

<h1 align="center">
  .Sloth
</h1>

<p align="center">
  Dotfiles for laziness
</p>

<p align="center">
<a href="https://twitter.com/intent/tweet?text=Be%20more%20productive%20by%20using%20.Sloth%20dotfiles%20framework%20%23dotSloth%20%23dotfiles%20%23productivityraptor&url=https%3A%2F%2Fgithub.com%2Fgtrabanco%2FdotSloth" title="Tweet about .Sloth"><img src="ic_twitter_share.svg" width="200" height="20" alt="Twitter share button" /></a>
</p>

<p align="right">
  Original idea by <a href="https://github.com/rgomezcasas">Rafa Gomez</a> &mdash;
  Based on <a href="https://github.com/CodelyTV/dotly">Dotly Framework</a> by <a href="https://codely.com">CodelyTV</a>
</p>

---

- [What you can do](#what-you-can-do)
- [Installing](#installing)
  - [One-liner install](#one-liner-install)
  - [Migration from Dotly](#migration-from-dotly)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Packages &amp; Recipes](#packages--recipes)
  - [Install any package in one command](#install-any-package-in-one-command)
  - [Create custom recipes](#create-custom-recipes)
  - [Dump &amp; import packages per machine](#dump--import-packages-per-machine)
- [Custom Scripts](#custom-scripts)
- [Init Scripts](#init-scripts)
- [Symlinks](#symlinks)
- [Auto Update](#auto-update)
- [Restorer](#restorer)
- [Testing](#testing)
- [Contributing](#contributing)
- [Roadmap](#roadmap)

---

## What you can do

.Sloth is a full dotfiles framework with its own CLI. Here are the most useful things you can do with it:

```bash
# 📦 Install a package (uses package manager or builds from source via recipes)
dot package add zsh
dot package add nix

# 📖 List all installed packages for this machine
dot package dump

# 🐚 Configure your shell (bash, zsh, or both)
dot core install --shell

# 🔗 Apply symlinks (dotbot YAML, platform-aware)
dot symlinks apply

# 📝 Create a new custom script from a template
dot script create

# 🔄 Update .Sloth to the latest stable version
dot core update

# 🚀 Check that everything was installed correctly
dot self core
```

### Shell prompt with git status

.Sloth ships with configurable shell prompts for Bash and Zsh that show your current Git branch, whether your working tree is clean or dirty, untracked files, and whether you're behind/ahead of the remote:

```
[main|📝]  →  your current branch + dirty state indicator
[v2.0.0|↑2] →  tag + 2 commits behind
```

### Init scripts — modular, lazy loading

Init scripts are loaded at shell startup on demand. Enable the ones you need:

```bash
dot init status          # See all available scripts and their enabled state
dot init enable nvm      # Enable NVM to load Node/npm/npx on shell startup
dot init enable autoupdate  # Check for .Sloth updates asynchronously
```

Custom init scripts go in `${DOTFILES_PATH}/shell/init.scripts/` — perfect for per-host configuration, loading secrets, or setting environment variables.

### Restore your dotfiles on any machine

Use the built-in restoration script to rebuild your dotfiles on a fresh machine. It supports GitHub, Keybase, iCloud, or any Git URL:

```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/dotSloth/HEAD/restorer)
```

## Installing

### One-liner install

```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/dotSloth/HEAD/installer)
```

or

```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/dotSloth/HEAD/installer)
```

Supported on **Linux**, **macOS**, and **FreeBSD**.

> .Sloth can be installed standalone or as a git submodule inside your dotfiles repository.

### Migration from Dotly

If you're currently using [Dotly](https://github.com/CodelyTV/dotly), migrate with:

```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/dotSloth/HEAD/dotly-migrator)
```

## Getting Started

1. **Restart your terminal** after installation.
2. **Check the installation**: `dot self core` — shows what was configured and what failed.
3. **Create your dotfiles repository** to back up your custom configuration:

   ```bash
   cd "$DOTFILES_PATH"
   git init
   git remote add origin git@github.com:${GITHUB_USER}/${GITHUB_DOTFILES_REPOSITORY}.git
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

4. **Customise** your config files in `$DOTFILES_PATH/shell/exports.sh` and `$DOTFILES_PATH/shell/paths.sh`.

> [!IMPORTANT]
> If you make your dotfiles repository public, be careful not to expose secrets, tokens, or passwords. You are responsible for this, not .Sloth developers.

## Configuration

Personalise your installation by editing files inside `$DOTFILES_PATH`:

| File | Purpose |
|------|---------|
| `$DOTFILES_PATH/shell/exports.sh` | Environment variables for your machine (`.Sloth` update period, active theme, etc.) |
| `$DOTFILES_PATH/shell/paths.sh` | Additional directories in `$PATH` |
| `$DOTFILES_PATH/shell/aliases.sh` | Custom shell aliases |
| `$DOTFILES_PATH/shell/functions.sh` | Custom shell functions |
| `$DOTFILES_PATH/shell/bash/themes/` | Bash prompt themes |
| `$DOTFILES_PATH/shell/zsh/themes/` | Zsh prompt themes |

Edit them all at once:

```bash
code "$DOTFILES_PATH"
```

.Sloth automatically loads `JAVA_HOME`, Python, Ruby, Go, Homebrew, MacPorts, Nix, and other common paths. For anything else, use a [custom recipe](#create-custom-recipes) or an [init script](#init-scripts).

## Packages & Recipes

.Sloth uses **recipes** (like installers) to handle software that needs special setup steps. Each recipe knows how to install, check, update, and uninstall a package.

### Install any package in one command

```bash
dot package add bun      # Bun runtime (downloads from GitHub)
dot package add nix      # Nix package manager
dot package add z        # z directory jumper
dot package add nvm      # Node Version Manager
```

Under the hood, .Sloth tries each recipe in turn. If a recipe matches, it uses it. Otherwise it falls back to your default package manager.

### Supported package managers

| Platform | Package managers |
|----------|-----------------|
| **Linux** | apt, brew, snap, dnf, pacman, yum, cargo, pipx, pip, gem, volta, npm |
| **macOS** | mas, brew, cargo, pipx, pip, volta, npm |

### Create custom recipes

Add your own recipes in `${DOTFILES_PATH}/package/recipes/`. See `deno.sh` as an example — it can be installed via a package manager or built from source, supports updates, and shows version info.

### Create your own package manager wrapper

If your package manager isn't built in, or you want to replace how one works, add your wrapper in `${DOTFILES_PATH}/package/managers/`. See `brew.sh` for a complete example — it handles dump, install, update, and backup.

### Dump & import packages per machine

Save which packages you have installed on each host, then restore them elsewhere:

```bash
dot package dump       # Export → creates a file per machine
dot package import     # Import → restores from a previous dump
```

## Custom Scripts

The framework encourages creating lightweight scripts rather than loading thousands of Bash functions:

```bash
dot script create
dot script install_remote <github-url>
```

.Sloth scripts are included (not executed separately), so they start ~10ms faster than Dotly-compatible scripts.

## Init Scripts

Init scripts are modular pieces of code loaded at shell startup. They reduce the number of functions loaded in every shell session.

```bash
dot init status           # Show all available scripts and their enabled state
dot init enable           # Interactive fzf picker — enable multiple scripts at once
dot init enable nvm       # Enable a specific script
dot init disable nvm      # Disable a script
```

Custom scripts go in `${DOTFILES_PATH}/shell/init.scripts/`.

## Symlinks

.Sloth uses [dotbot](https://github.com/anishathalye/dotbot) YAML files for symlink management, with platform-aware configs:

```bash
dot symlinks apply                  # Apply all symlinks
dot symlinks apply core             # Apply only core symlinks
dot symlinks apply conf.macos.yaml  # Apply a specific file
```

Backup modes: `--backup`, `--interactive-backup`, `--ignore-backup`.

## Auto Update

Keep .Sloth itself up to date:

```bash
dot core update              # Update now (sync mode)
dot core update --async      # Non-blocking background update
```

Configure auto-updates in `$DOTFILES_PATH/shell/exports.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `SLOTH_AUTO_UPDATE_MODE` | `auto` | `silent` \| `info` \| `prompt` \| `auto` |
| `SLOTH_AUTO_UPDATE_PERIOD_IN_DAYS` | `7` | Days between update checks |
| `SLOTH_UPDATE_VERSION` | `stable` | `stable` \| `latest` \| pinned semver tag |

```bash
dot self update --disable   # Temporarily disable updates
dot self update --enable    # Re-enable updates
```

## Restorer

The restorer rebuilds your entire dotfiles setup on a new machine. It clones your repo, updates .Sloth, installs packages, and applies symlinks — with validation, rollback, and progress logging.

```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/dotSloth/HEAD/restorer)
```

Add `restoration_scripts/` to your dotfiles repo for post-install automation (scripts that run automatically during restoration).

## Testing

.Sloth has a comprehensive test suite using [BATS-core](https://github.com/bats-core/bats-core):

```bash
bats tests/                    # All tests
bats tests/core/git.bats       # A single test file
bats --recursive tests/        # Recursive run
```

Currently **158+** tests covering core libraries, package managers, the update system, and integration paths.

---

# Contributing

PRs, issues, and feature suggestions are welcome. All contributions that respect our [Code of Conduct](.github/code-of-conduct.md) are appreciated. See the [Roadmap](#roadmap) if you want to know where to focus your efforts.

# Roadmap

Check the [project's issue tracker](https://github.com/gtrabanco/dotSloth/issues) for upcoming features and tracked issues.

---

*Tweet button image from* https://bikeroll.net *([source](https://bikeroll.net/es/img/ic_twitter_share.svg))*
