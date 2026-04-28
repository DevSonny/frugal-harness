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

## 2026-04-24 — 모델 자동 라우팅 정책 개정

### 완료된 작업
- Claude 기본을 opusplan에서 sonnet으로 변경하고, 복잡한 plan에만 Opus 권장 정책 추가
- Codex 기본값을 plan high / implementation medium으로 정리
- 복잡한 Codex standalone plan은 xhigh 재실행을 권장하도록 shared/codex-wrapper.md에 명시
- README.md / README.ko.md에 반복 사용 결과 가장 효율적이었던 라우팅 정책 반영
- ~/.claude 원본 파일과 ~/.codex/AGENTS.md, ~/.codex/config.toml에도 새 정책을 적용

### 주요 결정
- Opus는 직접 구현용이 아니라 고난도 planning 품질이 필요할 때만 사용자 승인 후 사용
- ~/.codex/AGENTS.md는 직접 편집하지 않고 shared/harness-core.md + shared/codex-wrapper.md에서 생성
- 정책, 설치 흐름, CLI 명령, 역할 분담이 바뀌면 README.md와 README.ko.md를 함께 갱신

## 2026-04-24 — CLAUDE/AGENTS 정책 리뷰 결정

### 완료된 작업
- shared/harness-core.md에 범용 품질 게이트 원칙 추가: 프로젝트 표준 명령 우선, 변경 유형별 build/test/lint/format/type 검증
- shared/codex-wrapper.md에 Codex 검증 실행 절차와 문서 fallback 순서(Gemini → Codex → Claude) 추가
- CLAUDE.md를 자연어 우선 오케스트레이션, Codex-only 코드 리뷰, 명시 승인 기반 fallback 정책으로 정리
- skills/*.md를 optional slash command용 짧은 프롬프트로 축소
- guard-code-edit.sh 차단 확장자를 Vue/Svelte/Astro/Dart/C#/F#/Scala/Elixir/Lua/Nix/R/Julia/CSS 계열까지 확장
- README.md / README.ko.md를 사용자가 선택한 상세 매뉴얼형 구조로 전면 재작성
- .gitignore의 literal \n 문제를 줄 단위 항목으로 수정하고 .codex / Zone.Identifier 부산물을 ignore 처리
- ~/.claude 설치본과 ~/.codex/AGENTS.md를 shared 원본 기준으로 재동기화

### 주요 결정
- 자연어가 기본 인터페이스이고 slash command는 선택 단축키로 유지
- 코드는 Codex가 구현/리뷰/커밋/푸시를 담당하고 Claude는 코드 리뷰를 하지 않음
- Claude 코드 구현 fallback은 사용자 명시 승인 시에만 허용하며 소스 편집 guard는 기본 유지
- README 전면 재작성은 한국어 초안 2개 중 상세 매뉴얼형을 선택해 반영

### 미해결/주의
- repo 루트의 빈 .codex 파일은 read-only bind mount로 보이며 rm 시 "device or resource busy"로 삭제 실패

## 2026-04-24 — Claude slash command 등록 설치 반영

### 완료된 작업
- install.sh의 스킬 다운로드 루프 직후에 ~/.claude/commands 생성 및 SKILLS 배열 기반 slash command 복사 로직 추가
- README.md / README.ko.md의 설치 구성 목록에 Claude Code slash command 등록 항목 추가

### 주의
- 현재 Codex 샌드박스가 /Users/son/.claude/commands 쓰기를 차단해 즉시 홈 디렉터리 등록은 실행하지 못함

## 2026-04-24 — statusline 세션 비용 데이터 조사

### 조사 결과
- Claude Code statusline stdin에는 `session_id`와 `transcript_path`가 포함되며, 현재 세션 비용은 해당 transcript JSONL의 `type=="assistant"` usage 토큰을 합산해 계산 가능
- Codex rollout의 `event_msg.payload.type=="token_count"` 안 `info.total_token_usage`는 rollout 파일 단위 누적값이며, 최신 이벤트를 사용하면 해당 rollout 세션 비용을 계산할 수 있음
- Gemini CLI 세션 토큰은 `~/.gemini/tmp/<project>/chats/session-*.json`의 `messages[] | select(.type=="gemini").tokens` 및 `model`에 저장됨

## 2026-04-24 — statusline 세션 비용 2줄 출력 구현

### 완료된 작업
- `scripts/lib-cost-tracker.sh` 추가: Claude transcript JSONL, 최신 Codex rollout, 오늘 최신 Gemini session JSON에서 세션 비용 계산
- `scripts/usage-statusline.sh`가 기존 1줄 사용량 출력 뒤에 `Claude/Codex/Gemini/Total` 비용 줄을 출력하도록 변경
- `install.sh`의 usage scripts 배포 목록에 `lib-cost-tracker.sh` 추가
- README.md / README.ko.md 설치 구성 설명에 statusline 세션 비용 표시 반영

### 주요 결정
- 비용 계산은 외부 HTTP/npx 없이 `jq`, `awk`, 로컬 파일만 사용
- Codex/Gemini의 cached 토큰은 input 총량에서 제외한 uncached input과 별도 cached rate로 계산해 중복 과금을 피함
- Claude transcript가 비었거나 읽을 수 없으면 Claude 비용과 Total은 `?`로 표시하고, Gemini 세션 파일이 없으면 `$0.00`으로 표시

### 에러 및 해결
- macOS awk에서 여러 줄 산술식과 `input` 변수명이 구문 오류를 일으켜 awk 변수명을 `in_tok` 등으로 바꾸고 산술식을 한 줄로 정리

## 2026-04-24 — session cost statusline 커밋 준비

### 검증
- `bash -n install.sh uninstall.sh scripts/*.sh` 통과
- `git diff --check` 통과
- 임시 HOME과 transcript JSONL로 `scripts/usage-statusline.sh` 샘플 실행 통과

### 주요 결정
- 신규 `scripts/lib-cost-tracker.sh`는 기존 scripts 셸 파일들과 맞춰 executable로 커밋

### 미해결/주의
- 현재 Codex 샌드박스에서 `.git/index.lock` 및 ref lock 파일 생성이 `Operation not permitted`로 막혀 일반 `git add`/`git commit`은 실패
- 임시 index/object directory로 commit object 생성은 가능했으나, `git push`는 `Could not resolve host: github.com`로 실패

## 2026-04-28 — usage Node 전환 및 자동 CLI 설치 정책

### 완료된 작업
- usage 대시보드를 jq/Bash JSON 파싱에서 Node.js 기반 scripts/usage.js로 전환
- Codex 사용량 선택 기준을 rollout 파일 mtime이 아니라 최신 token_count 이벤트 timestamp로 변경
- scripts/usage.sh와 scripts/usage-statusline.sh를 Node wrapper로 축소
- install.sh에서 jq prerequisite를 제거하고 Node/npm 필수 확인으로 변경
- installer가 누락된 Claude/Codex/Gemini CLI를 공식 설치 경로로 자동 설치하도록 변경
- uninstall.sh와 guard-code-edit.sh의 JSON 처리를 jq에서 Node로 변경
- 원격의 statusline 세션 비용 기능을 scripts/usage.js에 통합해 2줄 출력 유지

### 주요 결정
- curl | bash 하네스 설치 방식은 유지
- CLI 설치는 공식 하이브리드: Claude는 공식 native curl installer, Codex/Gemini은 npm
- FRUGAL_SKIP_CLI_INSTALL=1로 CLI 자동 설치를 건너뛸 수 있음
- scripts/lib-claude-window.sh와 scripts/lib-cost-tracker.sh 기능은 Node 파서로 흡수
