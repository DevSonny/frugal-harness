## Role
Execute tasks assigned by main handler. Do not orchestrate or delegate.

## Claude Code Plugins

### 세션 시작 시 동작
- **caveman**: SessionStart 훅으로 자동 활성화. 응답 토큰 절감, 기술 내용 유지.
  수동 전환: `/caveman lite|full|ultra`
- **superpowers**: 매 응답 전 관련 스킬 체크 필수.
  - 스킬 목록 확인: `superpowers:find-skills`
