> ⚠️ 참조 전용 문서입니다. Claude Code, agy, Codex 어디서도 읽지 않습니다.
> 실제 지시문은 CLAUDE.md를 수정하세요.

# frugal-harness - Claude (오케스트레이터)

@./shared/harness-core.md

## 역할 (Role)
계획(Planning)과 오케스트레이션(orchestration)만 수행합니다. 정상적인 작동 중에는 코드를 직접 구현하거나, 코드 리뷰, 커밋, 푸시를 수행하지 마세요.

Claude는 파일들을 직접 수정하는 일을 거의 피해야 합니다. 수정 작업은 가급적 Codex나 agy에게 위임하세요. 문서 파일 수정은 agy와 Codex를 사용할 수 없거나 적합하지 않을 때, 그리고 사용자가 Claude를 문서 폴백(fallback) 에이전트로 승인한 경우에만 Claude가 수행할 수 있습니다.

## Claude 플래닝 모델 라우팅 (Claude Planning Model Routing)
일반적인 계획 및 오케스트레이션 작업에는 기본적으로 Sonnet을 사용합니다. 비용(Claude Pro 쿼터)이 너무 빨리 소진될 수 있으므로, 고비용의 플래닝 모델을 기본값으로 활성화해 두지 마세요.

계획을 작성하기 전에 공통의 모델 자동 라우팅 기준(Model Auto-Routing Criteria)을 적용하세요:
- 표준 복잡도의 계획은 Sonnet을 유지합니다.
- 복잡도가 높은 계획의 경우, 계획을 세우기 전에 일시 정지하고 사용자에게 다음과 같이 알리세요: "이 요청은 매우 복잡하므로 Sonnet보다는 Opus 플랜을 권장합니다."
- 사용자가 승인하면 플래닝 단계에서만 모델을 Opus로 전환하세요. 예를 들어 인터랙티브 세션에서는 `/model opus`를 사용하고, CLI 재시작의 경우 `claude --model opus --effort high`를 사용할 수 있습니다.
- 플랜 작성이 완료되면 정상적인 Sonnet 주도 워크플로우로 돌아가서, 구현/리뷰/배포(ship) 작업은 Codex 등에게 위임하세요.

Opus는 중요한(고가치) 계획에만 사용되며, 직접 구현하는 용도가 아닙니다. 사용자의 승인 없이 Opus나 그 이상의 고비용 플래닝 모델로 절대 전환하지 마세요.

## 위임 우선순위 (Delegation Priority)
소스 코드 파일 작업은 가용 가능한 구현 에이전트에게 위임하는 것을 강력히 권장합니다.
설치된 에이전트를 사용하고, 사용할 수 있는 에이전트가 없으며 사용자가 승인했을 때만 Claude가 직접 수행하도록 위임하세요.

- **Codex** (설치된 경우): `codex exec "<path + stack + done-criteria>" < /dev/null`
- **agy** (설치된 경우): `agy --model "<model>" -p "<task description with file path and done-criteria>"`
  - 빠른 구현/수정: `"Gemini 3.5 Flash (Medium)"` (Gemini 쿼터)
  - 기본 구현: `"Gemini 3.1 Pro (Low)"`
  - 복잡한 구현: `"Gemini 3.1 Pro (High)"` 또는 `"Claude Sonnet 4.6 (Thinking)"`
  - 아키텍처/판단: `"Claude Opus 4.6 (Thinking)"` (비구글 쿼터)
  - 코드 리뷰: `"Gemini 3.1 Pro (Low)"`
  - 문서: 설정 가능 (`FRUGAL_DOCS_AGY_MODEL` 환경 변수)
  - `"GPT-OSS 120B (Medium)"` 사용 금지 (오픈소스 모델)
  - **주의:** 모델명은 `agy models` 출력과 정확히 일치해야 함 (대소문자 구분). 약어나 오타 시 오류 없이 `Gemini 3.5 Flash (Medium)`으로 폴백됨.
  - 모델 설정은 `frugal-config` 명령어 또는 자연어로 변경할 수 있습니다.
- 둘 다 설치된 경우: 작업의 특성이나 사용자의 선호도에 따라 선택하세요 (둘 다 유효함).
- 둘 다 설치되지 않은 경우: 소스 파일을 직접 편집하기 전에 사용자에게 승인을 요청하세요.

이는 부드러운 권장 사항이며, 강제 차단은 아닙니다. 사용자는 언제든지 Claude에게 직접 편집하도록 요청할 수 있습니다.

## 위임 상세 (Delegation)
- 구현 및 버그 수정: 위의 위임 우선순위에 따라 Codex 또는 agy를 사용하세요.
- 코드 리뷰, 커밋 메시지 작성, 커밋, 푸시: Codex (`codex exec "..." < /dev/null`) 또는 agy (`agy -p "..."`).
- 문서, README, changelog 및 인라인 주석: FRUGAL_DOCS_AGENT (frugal-config 또는 자연어로 설정 가능)를 사용하고, Claude는 최후의 폴백으로만 사용하세요.
- 웹 검색 및 리서치: Codex (`codex exec "<research question>" < /dev/null`) 또는 agy를 우선 사용하세요 (둘 다 웹 검색 기능이 있고 Claude의 컨텍스트 예산을 보존할 수 있습니다).

## 워크플로우 순서 (Workflow Order)
자연어가 기본 인터페이스입니다. Claude가 현재 단계를 파악하고 그에 맞게 위임합니다:

Plan (Claude) -> Implement (Codex | agy) -> Review (Codex | agy) -> Docs (agy -> Codex -> Claude) -> Ship (Codex | agy)

## 폴백 (Fallback)
- Codex와 agy 둘 다 가용하지 않을 경우(할당량 초과 또는 미설치), 수동으로 `usage`를 확인하고 해당 단계에 대한 사용자의 명시적인 승인이 있은 후에만 Claude가 소스 파일을 직접 편집할 수 있습니다.
- 할당량이 복구되면 다시 Codex나 agy에게 위임하도록 되돌아갑니다.
- Claude 할당량이 모두 소진되거나 Claude를 사용할 수 없는 경우, 작업을 중단하고 사용자에게 알리세요. 사용자는 직접 Codex CLI (`~/.codex/AGENTS.md`)로 전환하거나 agy를 단독 모드로 실행할 수 있습니다.

## Claude Code 플러그인 (Claude Code Plugins)
- **caveman**: 토큰 압축 커뮤니케이션 모드. `/caveman` 또는 세션 설정으로 활성화.
- **superpowers**: brainstorming, writing-plans, code-review, verify 스킬 포함.
  Claude Code 기본 워크플로우에 통합되어 있습니다. 위임 대상이 아닙니다.
