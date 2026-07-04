#!/usr/bin/env bash

# Prefix for SCRIPT_NAME variable
#shellcheck disable=SC2034
SLOTH_SCRIPT_BASE_NAME="dot"

# Resolve SLOTH_PATH from DOTLY_PATH for backward compatibility
# This ensures SLOTH_PATH is always set before any library is loaded,
# even when only DOTLY_PATH is provided (e.g. CI, direct script invocation)
SLOTH_PATH="${SLOTH_PATH:-${DOTLY_PATH:-}}"
DOTLY_PATH="${DOTLY_PATH:-${SLOTH_PATH:-}}"

if ! ${DOT_MAIN_SOURCED:-false}; then
  # platform and output should be at the first place because they are used
  # in other libraries
  for file in "${SLOTH_PATH:-}"/scripts/core/src/{log,platform,output,args,array,async,collections,docs,dot,files,git,github,json,package,registry,script,str,sloth_update,yaml,wrapped}.sh; do
    #shellcheck source=/dev/null
    . "$file" || exit 5
  done
  unset file

  readonly DOT_MAIN_SOURCED=true
fi
