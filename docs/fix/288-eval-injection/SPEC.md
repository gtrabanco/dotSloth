# fix/288-eval-injection

> Fix specification. Lighter than a feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Replace `eval "$download_command $script_raw_url"` in `scripts/script/install_remote:51` with a proper array-based invocation to eliminate the command injection vector via the user-provided `script_raw_url` argument.

## Issue

`#288` — tracked issue. Required. The PR must close it.

## Branch

`fix/288-eval-injection`

## Root cause

`install_remote` builds a curl command as a string (`download_command="$CURL_BIN -k -L -f -q $script_name_args"`) then executes it with `eval "$download_command $script_raw_url"`. The `script_raw_url` is a user-provided argument (`dot script install_remote <context> <url>`). A URL containing shell metacharacters (`; rm -rf ~`, `$(cmd)`, `` `cmd` ``) would be executed by `eval`.

Secondary issue: `if [ ! $? ]` on line 52 is always false — `$?` is consumed by the `[` command itself, so it always checks `[ ! 0 ]` which is false.

## Fix

1. Replace string-based command building with a bash array.
2. Replace `eval` with direct array expansion: `"${curl_args[@]}" "$script_raw_url"`.
3. Capture the exit code immediately: `curl_exit=$?` instead of `if [ ! $? ]`.
4. Keep `-k` flag (intentional for downloading from various sources — noted as a separate concern, not fixed here).

## Scope

- `scripts/script/install_remote` — lines 36-57
- No other files affected

## Acceptance criteria

- [ ] No `eval` in `scripts/script/install_remote`
- [ ] `script_raw_url` is passed as a single quoted argument to curl (no shell expansion)
- [ ] Exit code is captured immediately after the curl command
- [ ] `bash scripts/core/static_analysis` passes
- [ ] `bash scripts/core/lint` passes
- [ ] `make test` passes

## Testing requirements

Manual verification: `dot script install_remote test_context "https://example.com/raw/script.sh"` downloads the file without executing the URL as a command.
