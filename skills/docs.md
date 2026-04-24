# /docs — Write or update documentation

## When to use
- Writing or updating README
- API documentation
- Inline code comments
- Changelogs

## Steps
1. Pass the relevant files or diff to Gemini CLI first
2. Specify the doc type (README / API doc / changelog / comments)
3. Specify the language (Korean / English / both)
4. If Gemini is unavailable, fall back to Codex, then Claude

## Output
Concise documentation changes ready for review.

## Agent
Gemini CLI -> Codex CLI -> Claude Code fallback
