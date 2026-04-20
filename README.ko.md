[`🇺🇸 English`](./README.md)

# frugal-harness

> 플랜으로 설계하고, Codex로 구현하고, 저렴하게 배포하세요.

![License](https://img.shields.io/badge/license-MIT-blue) ![Stars](https://img.shields.io/github/stars/DevSonny/frugal-harness)

## 대상 요금제

월 $20 요금제를 위해 만들어졌습니다 — Claude Code Pro (Anthropic) 또는 ChatGPT Plus (OpenAI, Codex CLI 용도). 해당 플랜이라면 이 하니스가 딱 맞습니다.

## 이게 뭔가요

`frugal-harness`는 계획, 구현, 리뷰, 배포를 엄격하게 분리하고 싶은 Claude Code 사용자를 위한 가벼운 워크플로우 팩입니다. 계획은 Claude가 맡고, 코딩과 검증은 Codex에 위임하며, 작은 컨텍스트와 명확한 핸드오프, 낮은 비용을 우선합니다.

## 설치

```bash
bash <(curl -s https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh)
```

## 사용법

예측 가능한 실행 규율이 필요할 때 이 하니스를 사용하세요. 먼저 계획을 정하고, `codex exec`으로 구현을 Codex에 위임하고, 결과를 리뷰한 뒤, 마지막에 배포하세요. 각 핸드오프에는 파일 경로, 기술 스택, 완료 기준을 넣어 요청을 구체적으로 유지하세요.

## 스킬 (/plan, /review, /ship)

`/plan`은 코딩을 시작하기 전에 반드시 논의를 거치게 만듭니다.

`/review`는 구현 결과를 프로덕션 버그, 보안 문제, 성능 회귀, 테스트 누락 관점에서 점검합니다.

`/ship`은 최종 검증 절차를 실행하고, 메모리를 업데이트하고, 릴리스 전 diff를 요약합니다.

## 왜 가성비인가

핵심은 일을 덜 하는 것이 아닙니다. 중요한 곳에만 토큰과 집중력을 쓰는 것입니다. 계획에는 비싼 추론을 쓰고, 구현에는 더 저렴한 실행을 쓰고, 품질은 반복 가능한 체크로 보장합니다. 그래서 모든 단계에 고가 모델 비용을 쓰지 않고도 더 날카로운 워크플로우를 만들 수 있습니다.
