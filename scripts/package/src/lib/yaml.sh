#!/usr/bin/env bash

yaml::write_value() {
  local key value indent
  key="${1:-}"
  value="${2:-}"
  indent="${3:-0}"

  [[ -z "$key" ]] && return 1

  if [[ $indent -gt 0 ]]; then
    printf '%*s' "$((indent * 2))" ''
  fi

  if [[ -z "$value" ]]; then
    printf '%s: ""\n' "$key"
  else
    printf '%s: %s\n' "$key" "$value"
  fi
}

yaml::write_array_item() {
  local item indent
  item="${1:-}"
  indent="${2:-0}"

  [[ -z "$item" ]] && return 1

  if [[ $indent -gt 0 ]]; then
    printf '%*s' "$((indent * 2))" ''
  fi

  printf '  - %s\n' "$item"
}

yaml::write_array() {
  local key indent item
  key="${1:-}"
  indent="${3:-0}"

  [[ -z "$key" ]] && return 1

  shift 2
  shift "$((indent > 0 ? 0 : 0))"

  if [[ $indent -gt 0 ]]; then
    printf '%*s' "$((indent * 2))" ''
  fi

  printf '%s:\n' "$key"

  for item in "$@"; do
    if [[ $indent -gt 0 ]]; then
      printf '%*s' "$((indent * 2))" ''
    fi
    printf '  - %s\n' "$item"
  done
}

yaml::write_document() {
  local file comment line
  file="${1:-}"
  comment="${2:-}"

  [[ -z "$file" ]] && return 1

  if [[ -n "$comment" ]]; then
    printf '%s\n' "$comment" > "$file"
  else
    : > "$file"
  fi

  while IFS= read -r line; do
    printf '%s\n' "$line" >> "$file"
  done

  return 0
}

yaml::read_value() {
  local file key line value
  file="${1:-}"
  key="${2:-}"

  [[ -z "$file" || -z "$key" ]] && return 1
  [[ ! -f "$file" ]] && return 1

  while IFS= read -r line; do
    line="${line##  }"

    case "$line" in
      "$key":*)
        value="${line#*:}"
        value="${value## }"
        value="${value%\"}"
        value="${value#\"}"
        printf '%s' "$value"
        return 0
        ;;
    esac
  done < "$file"

  return 1
}

yaml::read_array() {
  local file key line in_array item
  file="${1:-}"
  key="${2:-}"

  [[ -z "$file" || -z "$key" ]] && return 1
  [[ ! -f "$file" ]] && return 1

  in_array=false

  while IFS= read -r line; do
    if $in_array; then
      line="${line##  }"

      case "$line" in
        -*)
          item="${line#-}"
          item="${item## }"
          item="${item%\"}"
          item="${item#\"}"
          printf '%s\n' "$item"
          ;;
        *)
          [[ -n "$line" ]] && [[ "$line" != \#* ]] && break
          ;;
      esac
    else
      stripped="${line##  }"
      case "$stripped" in
        "$key":*)
          in_array=true
          rest="${stripped#*:}"
          rest="${rest## }"

          if [[ "$rest" == \[*\] ]]; then
            rest="${rest#\[}"
            rest="${rest%\]}"
            printf '%s\n' "$rest" | tr ',' '\n' | sed 's/^ *//; s/ *$//; s/^"//; s/"$//'
            return 0
          fi
          ;;
      esac
    fi
  done < "$file"

  return 0
}
