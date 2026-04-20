[`🇰🇷 한국어`](./README.ko.md)

# frugal-harness

> Plan with Opus. Build with Codex. Ship cheap.

![License](https://img.shields.io/badge/license-MIT-blue) ![Stars](https://img.shields.io/github/stars/DevSonny/frugal-harness)

## Who is this for

Built for the $20/month tier — Claude Code Pro (Anthropic) or ChatGPT Plus (OpenAI, for Codex CLI). If that is your plan, this harness is for you.

## What is this

`frugal-harness` is a lightweight workflow pack for Claude Code users who want a strict split between planning, implementation, review, and shipping. It keeps planning in Claude, pushes coding and verification to Codex, and favors small context, explicit handoff, and low cost.

## Install

```bash
bash <(curl -s https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh)
```

## Usage

Use this harness when you want predictable execution discipline: define the plan first, delegate implementation to Codex with `codex exec`, review the result, and only then ship. Keep requests concrete by including file paths, stack details, and done criteria in each handoff.

## Skills (/plan, /review, /ship)

`/plan` forces discussion before coding starts.

`/review` checks the implementation for production bugs, security issues, performance regressions, and missing tests.

`/ship` runs the final verification flow, updates memory, and summarizes the diff before release.

## Why frugal

The point is not to do less work. The point is to spend tokens and attention where they matter: expensive reasoning for planning, cheaper execution for implementation, and repeatable checks for quality. That gives you a sharper workflow without paying premium model cost for every step.
