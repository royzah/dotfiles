# AGENTS.md

> Single source of truth for every AI agent here (Claude Code, Codex, Gemini
> CLI, Copilot). Bias: caution over speed; for trivial tasks, use judgment.

## 1. Think Before Coding

- State assumptions. Several interpretations? Present them, don't pick silently.
- Unclear? Stop, name what is confusing, and ask once, upfront.
- A simpler approach exists? Say so and push back when warranted.
- Search the codebase and stdlib before building something new.

## 2. Simplicity First

- Minimum code that solves the problem. No features, abstraction, or
  configurability beyond what was asked; no error handling for impossible cases.
- If 200 lines could be 50, rewrite it. Would a senior engineer call it
  overcomplicated? Then simplify.

## 3. Surgical Changes

- Every changed line traces to the request. Match existing style.
- Don't "improve" adjacent code, comments, or formatting; mention, don't fix.
- Remove imports/code that YOUR change orphaned; leave pre-existing dead code.

## 4. Goal-Driven Execution

- Turn the task into a verifiable goal: a bug fix starts from a failing test or
  repro; a refactor keeps tests green before and after.
- Multi-step work: a short plan, each step with its check (`step -- verify: x`).
- **Done means verified:** tests, lint, and type-check pass and the diff is
  read. "Should work" is not done. "Unrelated failure" needs proof on base.

## Code

- No silent failures, bare catches, or `except: pass`.
- No type escape hatches (`any`, `object`) without a justifying comment.
- Validate external input at the boundary. Timeouts on everything external.
- Never log secrets or PII. Never hardcode paths, commands, or the default branch.
- Pin dependencies, commit the lockfile, justify every new dep.
- Comments: only the why, one line. Mark landmines `// Intentional: X because Y`.
  Stale comments are bugs; TODOs need an owner, issue, or trigger.
- Plain ASCII in code and docs: no em dashes, unicode arrows, or emoji.
- Replies: concise and direct, lead with the recommendation.

## Git

- Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`,
  `chore:`, `ci:`, `perf:`), imperative subject <= 72 chars, one logical change.
- **Never** add `Co-authored-by` for AI or mention AI in commits or PRs.
- Never commit secrets or `.env`; keep a `.env.example` with fake values.
- PR description: what, why (issue link), how to verify.
- Branches `type/short-description`; `git worktree` for parallel work.

## Project Context

> Populate as you learn the project. Keep this file under ~150 lines; move
> detail into docs and link them here.

- **What it is:**
- **Stack:** language / framework / package manager / database
- **Dev environment:** Nix flake + direnv (`flake.nix`, `.envrc`); services
  via `compose.yaml`.
- **Commands:** install: | dev: | build: | test: | lint: | format: | type-check:
- **Layout:**
- **Domain terms:** one canonical name per concept (`CONTEXT.md` if many).

## Self-Maintenance

- Edit this file only; `CLAUDE.md`, `GEMINI.md`, and
  `.github/copilot-instructions.md` import it or hold tool-specific notes.
- Append to the sections below as you learn; never remove or weaken a rule
  without explicit approval.

## Gotchas

> Surprises that cost time, with the fix.

## Decision Log

> `- YYYY-MM-DD: <decision> -- <rationale>`

## Learned Conventions
