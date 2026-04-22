# /docs — Let Gemini write the words

## When to use
- Writing or updating README
- API documentation
- Inline code comments
- Changelogs
- Commit messages (all sizes)

## Why Gemini?
- Free tier: 1,000 req/day, 1M token context
- Great at reading large codebases and writing coherent docs
- Saves Claude and Codex quota for actual work

## Steps
1. Pass the relevant files or diff to Gemini CLI
2. Specify the doc type (README / API doc / changelog / comments)
3. Specify the language (Korean / English / both)
4. Review output and commit

## Example prompt for Gemini CLI
"Read the following code and write a Korean + English README.
Be casual, not formal. No translation-speak."

## Agent
Gemini CLI (free tier)
