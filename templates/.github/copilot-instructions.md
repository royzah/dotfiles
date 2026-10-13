# Copilot instructions

Project rules live in `AGENTS.md` at the repo root. Copilot in VS Code, Copilot
CLI, the cloud agent, and code review load it automatically; keep only
Copilot-specific notes here.

## Code review

- Flag silent failures, unvalidated input at boundaries, missing timeouts,
  secrets in code or logs, and unpinned or unjustified new dependencies.
- Flag changes that do not trace to the PR's stated goal, and code a senior
  engineer would call overcomplicated.
- One short comment per issue, on its line, with the suggested fix.
