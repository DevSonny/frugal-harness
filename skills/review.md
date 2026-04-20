# Review

Review the implemented code from a Staff Engineer perspective:

- Bugs that could explode in production
- Security vulnerabilities (missing auth, unvalidated input, exposed API keys)
- Performance regressions (N+1 queries, unnecessary loops)
- Missing tests
- Overuse of 'any' type or type assertions

Fix required items immediately via codex exec.
After fixing, do a self-review once more — if clean, run /ship.

---

# Review (한국어)

Staff Engineer 관점에서 구현된 코드를 검토해:

- 프로덕션에서 터질 수 있는 버그
- 보안 취약점 (인증 누락, 입력값 미검증, API 키 노출)
- 성능 회귀 가능성 (N+1 쿼리, 불필요한 루프)
- 테스트 누락 여부
- any 타입, 타입 단언 남용

수정 필요한 항목은 codex exec으로 바로 고쳐.
수정 후 다시 한 번 스스로 검토해서 이상 없으면 /ship 실행해.
