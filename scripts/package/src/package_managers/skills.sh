#!/usr/bin/env bash
# shellcheck disable=SC2034

skills_title='🧩 Skills'
SKILLS_DIR="${HOME}/.agents/skills"
SKILLS_DUMP_FILE_PATH="${SKILLS_DUMP_FILE_PATH:-${DOTFILES_PATH:-${HOME}/.agents}/agents/skill-lock.yaml}"

skills::title() {
  echo -n "🧩 Skills"
}

skills::is_available() {
  return 0
}

skills::setup() {
  :
}

skills::dump() {
  :
}

skills::import() {
  :
}
