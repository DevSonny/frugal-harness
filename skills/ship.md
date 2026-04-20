# Ship

Run all steps in order. If any step fails, fix and restart from the top:

1. codex exec "npx playwright test && npx eslint . && tsc --noEmit"
2. codex exec "remove all console.log and debug code"
3. Update .notes/memory.md with changes and decision rationale
4. Summarize git diff and show me

---

# Ship (한국어)

아래 순서대로 전부 실행해. 하나라도 실패하면 고치고 다시 시작해:

1. codex exec "npx playwright test && npx eslint . && tsc --noEmit"
2. codex exec "remove all console.log and debug code"
3. .notes/memory.md에 변경 사항, 결정 이유 기록
4. git diff 요약해서 나에게 보여줘
