# fix/296-restorer-rollback-symlinks

## Problem

`create_rollback_point()` saves a list of symlinks from `$HOME` to
`$ROLLBACK_DIR/symlinks.txt`, but `rollback()` only restores the dotfiles
directory — it never reads or restores the symlinks.

## Fix

1. **`create_rollback_point()`**: Replace `ls -la $HOME | grep '^l'` with a
   reliable null-delimited format using `find`:
   ```
   find "$HOME" -maxdepth 1 -type l -print0 | while IFS= read -r -d '' link; do
     printf '%s\0%s\0' "$(readlink "$link")" "$link"
   done > "$ROLLBACK_DIR/symlinks.txt"
   ```
   Format: `<target>\0<link_path>\0<target>\0<link_path>\0...`

2. **`rollback()`**: After restoring dotfiles, parse `symlinks.txt` and
   recreate each symlink:
   ```bash
   while IFS= read -r -d '' target && IFS= read -r -d '' link; do
     rm -f "$link" 2>/dev/null
     ln -s "$target" "$link" 2>/dev/null
   done < "$rollback_dir/symlinks.txt"
   ```

3. **Backward compat**: If `symlinks.txt` is empty or missing, skip silently
   (diagnostic-only mode).

## Acceptance criteria

- [ ] `create_rollback_point()` saves symlinks in the new null-delimited format
- [ ] `rollback()` restores symlinks from `symlinks.txt`
- [ ] Empty/missing `symlinks.txt` does not break rollback
- [ ] Shellcheck + shfmt clean
- [ ] No tests broken

## Branch

`fix/296-restorer-rollback-symlinks`
