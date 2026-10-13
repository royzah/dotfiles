# Copilot instructions

Repo rules live in `AGENTS.md` at the root. Copilot in VS Code, Copilot CLI,
the cloud agent, and code review load it automatically; keep only
Copilot-specific notes here.

## Code review

- Public repo: flag hostnames, employer names, work emails, or secrets.
- Shell: flag missing `set -euo pipefail`, unquoted expansions, non-idempotent
  steps, and `grep -q` at the end of a pipe under pipefail.
- Flag hardcoded install paths or methods that should be detected at runtime.
- One short comment per issue, on its line, with the suggested fix.
