---
name: initialize-awl
description: Configure or repair an Agentic Workflow Loop project through the awl CLI.
---

# Initialize AWL

Use this skill when a repository needs initial AWL setup or when `awl doctor`
reports a repairable setup issue.

1. Run `awl doctor --for init` first. Do not claim that a failed frozen
   contract, uncommitted worktree, missing Git history, credentials, or an
   unavailable agent is repaired automatically.
2. Run `awl doctor --repair` to apply safe AWL-owned fixes, including adding
   `.loop/` to the target repository `.gitignore`. Tell the operator to commit
   that change before strict initialization or execution.
3. Run `awl init` in a terminal. Its wizard discovers Pi and OpenCode, lists
   models from the selected local agent configuration, records the chosen
   provider/model, and asks before enabling setup integrations or trusting the
   execution boundary. When Engram is missing, accept its verified official
   binary installation into `~/.local/bin`, then let AWL run the native
   `engram setup pi` and `engram setup opencode` commands for every installed
   backend. Use `awl install-engram` for this single repair.
   Choose local Engram by default, or provide `--engram-url https://host:7437`
   for an externally managed HTTP service. This sets `ENGRAM_URL` only for AWL
   agent sessions; it does not replace the local binary needed by native MCP
   integrations.
4. If the target lacks an agentic-workflow workspace, accept the project setup.
   AWL installs the selected workflow skills and invokes the native
   `init-workspace` action in a fresh configured agent session. Do not invent
   an `init-workflow` command: the installed portable skill is named
   `init-workspace`.
5. Re-run `awl doctor --for init --strict` after committing `.gitignore`; run
   `awl doctor --for execute --strict` only when a trusted model route and all
   execution prerequisites are present.

For automation or a non-interactive shell, pass the explicit selections:

```sh
awl init --yes --agent pi --model provider/model --trusted-target
```
