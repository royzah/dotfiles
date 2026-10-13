# AGENTS.md

> Single source of truth for every AI agent in this repository (Claude Code,
> Codex, Gemini CLI, Copilot). Read at session start. Follow unconditionally.

## Self-Maintenance

- Edit this file, never `CLAUDE.md`, `GEMINI.md` or
  `.github/copilot-instructions.md`; those only point here.
- Populate **Project Context** when you discover stack, structure, or tooling.
- Append to **Decision Log** when a significant decision is made.
- Append to **Learned Conventions** when a pattern is established.
- Never remove or weaken rules without explicit approval.
- Bullet points only. Keep it lean: past ~150 lines, move detail into
  separate docs and point to them here.

## Project Context

> Populate and maintain as you learn about the project.

- **What it is:**
- **Language / runtime:**
- **Framework:**
- **Package manager:**
- **Database:**
- **Dev environment:** Nix flake + direnv (`flake.nix`, `.envrc`); services
  via `compose.yaml`.
- **Key commands:** install: | dev: | build: | test: | lint: | format: |
  type-check: | migrate:
- **Directory structure:**
- **External services / APIs:**
- **Domain language:** keep shared vocabulary in `CONTEXT.md` if the domain
  has terms that are easy to confuse; one canonical name per concept.

## Working Discipline

- State assumptions; ask once, upfront, when a requirement is unclear.
  Several interpretations? Present them, don't pick silently.
- Surgical changes only: every changed line traces to the request. Mention
  adjacent issues, don't fix them unasked. Match existing style.
- Simplicity over cleverness. No speculative abstraction, no features or
  configurability beyond what was asked.
- Search the codebase and stdlib before building something new.
- Never hardcode paths, commands, or the default branch; read project config.
- "Not related to our changes" needs proof: run the check on the base branch.
- **Done means verified:** run tests, lint, and type-check, then read the
  diff. "Should work" is not done.
- Bug fixes start from a failing test or repro and end with it in the suite.

## Code

- No silent failures, bare catches, or `except: pass`.
- No type escape hatches (`any`, `object`) without a justifying comment.
- Validate external input at the boundary; trust it after parsing.
- Timeouts on everything external. Never log secrets or PII.
- Pin dependency versions and commit the lockfile. Justify every new dep.

## Comments

- Only the why, never the what. One line where possible.
- Mark landmines: `// Intentional: X because Y`.
- Stale comments are bugs; fix them with the code they describe.
- TODOs need an owner, an issue link, or a trigger.

## Communication

- Concise and direct. Lead with the recommendation.
- Plain ASCII only in code and docs: no em dashes, unicode arrows, or emoji.

## Git

- Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`,
  `chore:`, `ci:`, `perf:`. Scope when useful: `feat(auth): ...`.
- One logical change per commit; each commit builds and passes checks.
- Subject imperative, 72 chars max. Body only when the why isn't obvious.
- **Never** add `Co-authored-by` for AI or mention AI in commits or PRs.
- Never commit secrets or `.env`; keep a `.env.example` with fake values.
- PR description: what, why (with issue link), how to verify.
- Branches: `type/short-description`. Use `git worktree` for parallel work.

## Gotchas

> Append surprises that cost time, with the fix.

## Decision Log

> Append: `- YYYY-MM-DD: <decision> -- <rationale>`

## Learned Conventions

> Append when patterns are established.
