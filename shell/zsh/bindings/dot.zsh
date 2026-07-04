dot-widget() {
  "${SLOTH_PATH:-}/bin/dot"
}

zle -N dot-widget
bindkey '^f' dot-widget
