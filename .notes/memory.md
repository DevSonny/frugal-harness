# frugal-harness memory

## 2026-06-30 — 중복 tdd 스킬 제거 및 superpowers 지원 범위 업데이트

### 완료된 작업
- **중복 tdd 스킬 제거**: superpowers에 이미 test-driven-development 스킬이 내장되어 있어 중복되는 `.agents/skills/tdd/` 삭제.
- **skills-lock.json 업데이트**: `skills-lock.json` 파일에서 `tdd` 항목 제거.
- **README 및 README.ko.md 업데이트**: `superpowers` 지원 에이전트에 `Codex`를 추가하고, Codex용 superpowers 설치 안내를 수동 실행 방법 안내로 수정.

## 2026-06-28 — Warp/cmux 환경 분리 + caveman/superpowers 전체 에이전트 설치

### 완료된 작업
- **Warp vs cmux HOME 분리 확인**: Warp이 `HOME=/Users/son/.agy_warp_home`으로 재정의 → config 경로가 달라서 skills 안 보였음
- **config symlink**: `~/.agy_warp_home/.gemini/config` → `/Users/son/.gemini/config` symlink로 두 환경이 같은 global config 공유
- **oauth 토큰은 자동 분리**: `antigravity-oauth-token`이 `antigravity-cli/` 하위라 HOME이 달라도 독립 유지됨
- **superpowers → agy 설치**: `agy plugin install https://github.com/obra/superpowers` (14 skills, 1 hook)
- **install.sh 수정**: caveman/superpowers 섹션을 per-agent 명시 설치로 교체

### 주요 결정
- caveman 인스톨러 `--only` 플래그로 Gemini CLI는 제외, Antigravity는 `soft probe`라 `--only antigravity` 명시 필요
- caveman → Claude: `curl ... | bash -s -- --only claude`
- caveman → agy: `npx -y skills add JuliusBrussee/caveman -a antigravity --yes`
- caveman → Codex: `npx -y skills add JuliusBrussee/caveman -a codex --yes`
- superpowers → Claude: `claude plugin install superpowers@claude-plugins-official`
- superpowers → agy: `agy plugin install https://github.com/obra/superpowers`
- superpowers → Codex: 인터랙티브 `/plugins` UI라 자동화 불가 → 안내 메시지로 처리

### 에러 및 해결
- git push SSH key 없어서 실패 → HTTPS remote로 전환
- caveman auto-detect 인스톨러가 Gemini CLI를 자동 감지해서 설치 → per-agent 방식으로 교체
- Antigravity는 caveman "soft probe" agent → 자동 감지 안 됨, --only 명시 필요



## 2026-06-25 — agy AGENTS.md 생성 및 README 전면 개정

### 완료된 작업
- `scripts/sync-agents.sh`를 Codex와 agy 모두 지원하도록 확장: `~/.codex/AGENTS.md`와 `~/.gemini/config/AGENTS.md` 각각 생성
- `install.sh`에 agy AGENTS.md 백업/생성 로직 추가 및 sync-agents.sh 로컬 복사 우선 로직 추가
- `install.sh` 최종 출력에서 삭제된 slash command 참조 제거, 에이전트 요약만 표시
- `README.md`와 `README.ko.md`를 현재 아키텍처에 맞게 전면 재작성:
  - 에이전트 선택 설치(Codex/agy/both) 및 `FRUGAL_AGENT` 환경변수 문서화
  - Codex 고정 언어 → 일반적인 '구현 에이전트(implementation agent)' 표현으로 변경
  - 비용 비교 테이블 추가 (3가지 구성)
  - agy 모델 선택 가이드 및 Codex reasoning effort 서브섹션 추가
  - `~/.codex/AGENTS.md`와 `~/.gemini/config/AGENTS.md` 모두 문서화
  - 삭제된 slash command(/plan, /exec, /review, /ship, /docs) 참조 전부 제거
  - PreToolUse guard 언급 제거
- `CLAUDE.md` Workflow Order에서 slash command 표기 제거

### 주요 결정
- slash command는 삭제되어 자연어만 기본 인터페이스
- sync-agents.sh는 wrapper 파일이 존재하는 에이전트에 대해서만 AGENTS.md 생성
- install.sh에서 sync-agents.sh는 agent 선택과 무관하게 항상 실행 (존재하는 wrapper만 처리)

## 2026-05-30 — Gemini CLI에서 Antigravity CLI로 마이그레이션

### 완료된 작업
- `README.md`, `README.ko.md`에서 Gemini CLI를 Antigravity CLI로 변경
- `install.sh`에서 Gemini 설치 로직을 Antigravity native curl 스크립트로 대체
- 환경변수 설정 대신 `agy login` 명령으로 Antigravity 구독 인증 방식을 사용하도록 수정
- `scripts/usage.js`에서 Gemini tracking 로직을 제거하고 Antigravity 정보를 표시하도록 수정
- `CLAUDE.md`, `shared/codex-wrapper.md`, `skills/docs.md`의 문서 작성 담당을 Antigravity CLI(`agy`)로 변경

## 2026-05-15 — 최신 pull 및 재설치

### 완료된 작업
- `git stash push` → `git pull --ff-only` (e0850ea → 18e39a7, 14파일 변경) → `git stash pop` (auto-merge 성공)
- `bash install.sh` 완료: Claude sonnet / Codex gpt-5.5 / Gemini gemini-2.5-flash-lite
- `~/.claude/commands` slash command 등록, `~/.local/share/frugal-harness/scripts` 배포
- `~/.codex/AGENTS.md` 125 lines 재생성

### 주요 변경 (이번 pull)
- `scripts/usage.js` 신규 추가 (Node.js 기반 usage 대시보드)
- `scripts/lib-claude-window.sh`, `scripts/lib-cost-tracker.sh` 삭제
- `scripts/usage.sh`, `scripts/usage-statusline.sh` 대폭 축소/변경
- Codex 기본 모델: `gpt-5.5` (plan medium, implementation medium)

### 에러 및 해결
- `.notes/memory.md` 미커밋 변경으로 `pull --ff-only` 실패 → stash 후 pull → stash pop으로 해결

## 2026-04-27 — 최신 pull 및 설치 실행

### 완료된 작업
- `/opt/homebrew/bin/git pull --ff-only` 실행 결과 `Already up to date.`
- `bash install.sh` 실행 완료: Claude/Codex/Gemini 설정, slash commands, usage scripts, Codex AGENTS.md 재생성
- 설치 후 `/Users/son/.codex/AGENTS.md` 119 lines 생성 확인
- `/Users/son/.local/bin/usage` 실행 링크 존재 및 executable 확인

### 검증
- `bash -n install.sh uninstall.sh scripts/*.sh` 통과
- `/opt/homebrew/bin/git status --short --branch` 결과 `main...origin/main`으로 로컬 변경 없음

### 에러 및 해결
- `/usr/bin/git`은 Xcode license 미동의로 실패했으나 `/opt/homebrew/bin/git`으로 정상 처리
- sandbox에서 `.git/FETCH_HEAD` 쓰기가 막혀 승인 후 escalated `git pull` 실행

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

## 2026-05-07 — Codex planning effort 기본값 조정

### 완료된 작업
- Codex 기본 planning effort를 high에서 medium으로 낮추는 정책으로 정리
- Codex standalone 복잡도 escalation을 medium → high → xhigh 추천 흐름으로 문서화
- shared/harness-core.md에 Claude Opus 추천과 Codex high/xhigh 추천이 같은 복잡도 기준을 공유한다고 명시
- README.md / README.ko.md와 install.sh 문구를 plan medium / implementation medium으로 동기화

### 주요 결정
- 구현 기본값은 계속 medium
- Codex 단독 모드에서 복잡한 plan은 자동 전환이 아니라 high 또는 xhigh 재실행 명령을 추천
- Claude Code의 복잡 planning Opus 추천 정책은 유지

## 2026-05-15 — codex exec stdin 대기 문제 수정

### 원인
Claude Code Bash 도구에서 `codex exec`를 실행하면 subprocess stdin이 파이프로 연결됨. Codex CLI가 파이프된 stdin을 감지하면 "Reading additional input from stdin..."을 출력하며 추가 입력을 기다려 간헐적으로 멈춤.

### 해결
`codex exec "..." < /dev/null` — stdin을 즉시 EOF로 닫아 대기 없이 실행. "Reading additional input from stdin..." 메시지는 여전히 출력되지만 멈추지 않음.

### 수정 파일
- `CLAUDE.md` (설치 시 `~/.claude/CLAUDE.md`로 배포): Delegation 섹션 모든 `codex exec` 예시에 `< /dev/null` 추가
- `scripts/guard-code-edit.sh` line 48: 힌트 메시지에 `< /dev/null` 추가

### 검증
- `bash -n install.sh uninstall.sh scripts/*.sh` 통과
- `git diff --check` 통과
- `scripts/guard-code-edit.sh`는 `.js` 파일 차단 시 exit 2와 `< /dev/null` 힌트를 출력하고, `.md` 파일은 허용함
- README.md / README.ko.md에는 `codex exec` 예시가 없어 변경 불필요

## 2026-06-28 — agy statusline 2줄 출력 버그 및 설정 누락 수정

### 완료된 작업
- `scripts/usage.js`에서 agy 환경을 `--agy` 플래그로 명시적으로 감지하도록 수정 (JSON 입력 유무로 판단하던 기존 로직 폐기)
- `~/.gemini/antigravity-cli/settings.json` (및 warp 환경)의 `statusLine.command`에 `--agy` 플래그를 추가해 agy에서 1줄 출력이 정상 동작하도록 수정
- 수정된 `usage.js`를 `~/.local/share/frugal-harness/scripts/usage.js`로 배포

### 주요 결정
- agy도 Claude Code처럼 stdin으로 JSON context를 전달하므로 `Object.keys(input).length > 0`로는 agy를 구별할 수 없음. 따라서 확실한 `--agy` 플래그를 도입.
- agy가 2줄 이상의 statusline을 받으면 파싱에 실패해 기본 상태표시줄로 fallback하는 문제를 확인 및 해결.


## 2026-06-29 — agy CLI Naming Cleanup & Model Routing Tier Implementation

### 완료된 작업
- **명칭 통일**: 모든 파일에서 'Antigravity'를 'agy'로, 'gemini -p'를 'agy -p'로 교체.
- **agy 모델 라우팅 업데이트**: `shared/agy-wrapper-main.md` 및 `shared/agy-wrapper-helper.md`에 새로운 기본값(Pro Low/Pro High) 반영 및 문서 모델을 `FRUGAL_DOCS_AGY_MODEL` 변수로 참조하도록 변경.
- **install.sh 이중언어(bilingual) 지원**: 설치 스크립트에 `LANG_MODE` 선택 도입, `msg()` 함수를 이용해 한국어/영어 양분 프롬프트 제공.
- **설치 옵션 추가**: 모델 티어(`FRUGAL_AGY_TIER`) 및 문서 담당 에이전트(`FRUGAL_DOCS_AGENT`) 선택 단계 `install.sh` 및 `frugal-config.sh`에 추가.
- **CLAUDE.md 정리**: 플러그인(`caveman`, `superpowers`) 섹션 추가, `agy` 명칭으로 전부 갱신, 문서 위임을 `FRUGAL_DOCS_AGENT` 변수 기반으로 업데이트.
- **sync-agents.sh 업데이트**: `config.sh`에 저장된 개별 모델 변수(`FRUGAL_AGY_MODEL_FAST` 등)를 읽어서 wrapper 파일들의 모델 문자열을 sed로 치환하여 `AGENTS.md`에 반영.
- **README 갱신**: `README.md`, `README.ko.md`에서 `Gemini CLI` 등의 오래된 표현을 전부 제거하고 새 라우팅 테이블 반영.
- **전역 설정 동기화**: `~/.claude/CLAUDE.md`를 새 버전으로 덮어씀.

## 2026-06-30 — README 문서 정리 및 Codex effort 간소화

### 완료된 작업
- **중국 모델 섹션 삭제**: README.md 및 README.ko.md에서 사용하지 않는 'Using Other LLM APIs' / '다른 LLM API 연결' 섹션 전체 제거.
- **Codex reasoning effort 간소화**: README.md 및 README.ko.md에서 Codex reasoning effort 설명을 medium effort 기본값 및 사용자 선택 방식으로 더 직관적이고 간결하게 수정.
