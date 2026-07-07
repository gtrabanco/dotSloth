#!/usr/bin/env bash

# The Go `yq` (mikefarah/yq) and `python-yq` (kislyuk/yq) both ship a `yq`
# executable, so Homebrew refuses to install python-yq while the Go yq is
# linked ("Cannot install python-yq because conflicting formulae are
# installed"). Unlink the Go yq first; reversible with `brew link yq`.
python-yq::_unlink_conflicting_yq() {
  if platform::command_exists brew && brew list --versions yq > /dev/null 2>&1; then
    brew unlink yq > /dev/null 2>&1 || true
  fi
  return 0
}

python-yq::install() {
  script::depends_on python3-pip

  if [[ -n "${1:-}" && $1 == "--force" ]] && python-yq::is_installed; then
    if platform::command_exists brew; then
      python-yq::_unlink_conflicting_yq
      brew reinstall python-yq

    elif
      platform::command_exists python3 &&
        python3 -c "import pip; print(pip.__version__)" > /dev/null 2>&1
    then
      python3 -m pip install --ignore-installed --user --no-cache-dir yq
    else
      output::error "Unable to locate any valid package manager to force install python-yq"
      return 1
    fi

    python-yq::is_installed && return 0

  fi

  if
    ! python-yq::is_installed &&
      platform::command_exists brew &&
      python-yq::_unlink_conflicting_yq &&
      brew install python-yq &&
      python-yq::is_installed
  then
    return 0
  fi

  if
    ! python-yq::is_installed &&
      platform::command_exists pip3 &&
      python3 -m pip install --user --no-cache-dir yq &&
      python-yq::is_installed
  then
    output::solution "yq installed!"
    return 0
  fi

  output::error "yq could not be installed"
  return 1
}

python-yq::is_installed() {
  # Because there is another tool called yq as well
  platform::command_exists yq && yq --help | grep -q "https://github.com/kislyuk/yq"
}
