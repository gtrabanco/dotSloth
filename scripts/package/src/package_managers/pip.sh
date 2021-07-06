#!/usr/bin/env bash

pip_title='🐍 pip'
PYTHON_DUMP_FILE_PATH="$DOTFILES_PATH/langs/python/$(hostname -s).txt"

pip::is_available() {
  platform::command_exists pip3
}

pip::is_installed() {
  [[ -n "${1:-}" ]] && pip3 show "$1" &> /dev/null
}

# Not define the function because it is not possible to do it with pip
# pip::package_exists() {
#   return
# }

pip::install() {
  [[ -n "${1:-}" ]] && pip::is_available && pip3 install "$1"
}

pip::update_all() {
  outdated=$(pip3 list --outdated | tail -n +3)

  if [ -n "$outdated" ]; then
    echo "$outdated" | while IFS= read -r outdated_app; do
      package=$(echo "$outdated_app" | awk '{print $1}')
      current_version=$(echo "$outdated_app" | awk '{print $2}')
      new_version=$(echo "$outdated_app" | awk '{print $3}')
      info=$(pip3 show "$package")

      summary=$(echo "$info" | head -n3 | tail -n1 | sed 's/Summary: //g')
      url=$(echo "$info" | head -n4 | tail -n1 | sed 's/Home-page: //g')

      output::write "🐍 $package"
      output::write "├ $current_version -> $new_version"
      output::write "├ $summary"
      output::write "└ $url"
      output::empty_line

      pip install -U "$package" 2>&1 | log::file "Updating pip app: ${package}"
    done
  else
    output::answer "Already up-to-date"
  fi
}

pip::dump() {
  PYTHON_DUMP_FILE_PATH="${1:-$PYTHON_DUMP_FILE_PATH}"

  if package::common_dump_check pip3 "$PYTHON_DUMP_FILE_PATH"; then
    pip3 freeze | tee "$PYTHON_DUMP_FILE_PATH" | log::file "Exporting ${pip_title} packages"

    return 0
  fi

  return 1
}

pip::import() {
  PYTHON_DUMP_FILE_PATH="${1:-$PYTHON_DUMP_FILE_PATH}"

  if package::common_import_check pip3 "$PYTHON_DUMP_FILE_PATH"; then
    pip3 install -r "$PYTHON_DUMP_FILE_PATH" | log::file "Importing ${pip_title} packages"

    return 0
  fi

  return 1
}
