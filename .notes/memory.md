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

## 2026-04-24 — 공통 하네스 분리

### 완료된 작업
- 공통 정책을 shared/harness-core.md로 분리
- Codex standalone 규칙을 shared/codex-wrapper.md로 분리
- scripts/sync-agents.sh 추가 및 ~/.codex/AGENTS.md 자동 생성 구조 적용
- Claude wrapper는 @./shared/harness-core.md import + 역할/위임 규칙만 유지

### 주요 결정
- Codex/Gemini 쿼터 고갈 시 Claude 임시 대체는 유지
- Claude unavailable 시 Codex는 ~/.codex/AGENTS.md로 단독 plan → build → review → commit → push 수행
- 커밋 메시지는 Gemini가 아니라 Codex가 직접 작성
