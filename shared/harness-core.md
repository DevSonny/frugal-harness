# frugal-harness - Shared Harness Core

These rules apply no matter which agent is running the task.

## Memory
- Before starting any task, if `.notes/memory.md` exists, read it first.
- After completing a task, record key decisions, errors, and solutions in `.notes/memory.md`.

## No Giving Up
- When debugging a failed implementation, do not ask the user for help until you have tried 3 distinct approaches.
- Requirements, edge cases, product choices, credentials, and destructive actions may still require user confirmation before work begins.
- Try a different approach before escalating.
- "Done" means every relevant item on the completion checklist has passed.

## Before Starting
- If the goal is unclear, ask exactly one clarifying question before touching code.
- For new feature requests, ask about important edge cases and failure scenarios before implementation.
- If changing 3 or more files, confirm the plan first.
- Check the file structure before reading files, and avoid unnecessary file exploration.

## Model Auto-Routing Criteria
Use the cheapest capable path by default, and only raise planning effort when the request actually needs it.

Treat a task as high-complexity planning work when any of these apply:
- 10 or more files are likely to change.
- Cross-system or cross-module dependency analysis is required.
- Architecture, database schema, or API design is changing.
- The request is a broad rewrite or large refactor of existing code.
- The user is asking for judgment-heavy planning, such as "design this", "change the structure", or "what is the best approach".

Treat a task as standard-complexity work when it is limited to:
- A single file or a specific function.
- A bug fix, type error fix, or focused test addition.
- Implementation from a concrete plan that already defines the scope and acceptance criteria.

## Token Saving
- Read only necessary files.
- Do not reread the same file in the same session unless it may have changed.
- Keep responses focused on the task.
- If 60% of context is used, compact or summarize before continuing.

## Security
- Always use `.env` or the platform's secret manager for environment variables and API keys.
- Never hardcode secrets, tokens, API keys, passwords, or private endpoints.
- New API endpoints must include input validation and authentication checks.
- Use parameter binding for database queries. Never concatenate user-controlled strings into SQL.

## Code Quality
- Follow the existing project style, tooling, and language ecosystem norms.
- Prefer precise types, explicit interfaces, idiomatic formatting, and standard static analysis for the stack in use.
- Do not leave debug logs, dead code, commented-out code, unused files, or temporary instrumentation.

## Quality Gate
- For code changes, discover the project's standard verification commands before inventing new ones. Check README files, package manifests, Makefile/Justfile/Taskfile, CI config, and language-specific project files.
- Run the relevant verification layers for the change: build/compile, tests, static analysis/lint, format check, and type/static-correctness checks when the project supports them.
- For documentation or configuration-only changes, run only affected validation such as Markdown checks, JSON/YAML/TOML parsing, link checks, generation scripts, or shell syntax checks.
- If a relevant verification command cannot be found or cannot run, state exactly what was skipped, why it was skipped, and what manual review was performed instead.

## Completion Checklist
1. Relevant quality gate checks pass for the files and behavior changed.
2. Debug code and temporary instrumentation are removed.
3. Commit and push are complete when the task requires shipping.
4. `.notes/memory.md` is updated with durable lessons or decisions.
5. `README.md` and `README.ko.md` are checked against the current behavior. Update both when policies, installation flow, CLI commands, roles, or user-facing behavior change; otherwise state that README changes were not needed.
