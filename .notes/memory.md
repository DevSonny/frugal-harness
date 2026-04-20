# frugal-harness memory

## 2026-04-20 — 전면 재구성

### 완료된 작업
- 8개 파일 전부 지정된 스펙으로 재작성
- skills/ 디렉토리: plan.md, exec.md, review.md, docs.md, ship.md
- install.sh: 실행 권한 부여 (chmod +x)
- README.md: 영문/한국어 bilingual, anchor 기반 토글
- CLAUDE.md: 3-에이전트 구조 (Opus/Codex/Gemini) + 워크플로우 규칙

### 주요 결정
- 워크플로우: /plan → /exec → /review → /docs → /ship
- Gemini CLI를 문서 전담으로 분리 (무료 1,000 req/일)
- [USERNAME]을 DevSonny로 교체해 install.sh curl URL 완성

### 에러 및 해결
- codex exec 명령이 stdin 대기로 멈춤 → Write 도구로 직접 파일 작성

## 2026-04-20 — usage 대시보드 추가

### 완료된 작업
- scripts/usage.sh: Claude/Codex/Gemini 사용량 통합 리포트 커맨드
- ~/.local/bin/usage 심링크 설치
- ~/.claude/settings.json statusline: 🤖(msgs) ⚡(threads) ♊(sessions) 지표 추가
- install.sh: usage 커맨드 설치 로직 추가

### 데이터 소스
- Claude: ~/.claude/stats-cache.json (jq)
- Codex: ~/.codex/state_5.sqlite → threads 테이블 (sqlite3)
- Gemini: ~/.gemini/tmp/*/chats/*.json (jq 토큰 합산)

### 에러 및 해결
- macOS bash 3.2에서 mapfile 없음 → while read -d '' 루프로 교체
- Codex read-only 샌드박스로 파일 쓰기 차단 → Write 도구로 직접 작성
