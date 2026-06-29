# Remove Redundant TDD Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the redundant `.agents/skills/tdd` directory, delete the `tdd` entry from `skills-lock.json`, update the `README.md` and `README.ko.md` files to reflect superpowers support for Codex, and push the changes.

**Architecture:** Deletion and documentation update.

**Tech Stack:** Git, Markdown, JSON.

## Global Constraints
- Maintain valid JSON syntax in `skills-lock.json`.
- Maintain bilingual synchronization between English and Korean README documents.
- Run project validation checks before pushing.

---

### Task 1: Delete redundant `.agents/skills/tdd/` directory

**Files:**
- Delete: `.agents/skills/tdd/`

- [ ] **Step 1: Remove .agents/skills/tdd/ using Git**
  Run: `git rm -r .agents/skills/tdd/`
  Expected: Git removes the directory and tracks deletion.

- [ ] **Step 2: Verify deletion**
  Run: `ls -la .agents/skills/tdd`
  Expected: Output states that the directory does not exist.

---

### Task 2: Remove 'tdd' entry from `skills-lock.json`

**Files:**
- Modify: `skills-lock.json`

- [ ] **Step 1: Remove the 'tdd' key block**
  Locate the `"tdd"` key block in `skills-lock.json` (lines 190–195) and remove it, along with the trailing comma from `"setup-pre-commit"` (line 189) if needed or by keeping valid JSON format.
  Expected: JSON structure is intact.

- [ ] **Step 2: Validate skills-lock.json syntax**
  Run: `node -e "JSON.parse(require('fs').readFileSync('skills-lock.json'))"`
  Expected: Command exits successfully with no output (valid JSON).

---

### Task 3: Update README.md Optional Skills Table and Codex Guide

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update superpowers row in table**
  Find line 113:
  ```markdown
  | **superpowers** | Claude Code, agy | Recommended | Adds powerful skills and extra capabilities to your agents. |
  ```
  Change to:
  ```markdown
  | **superpowers** | Claude Code, agy, Codex | Recommended | Adds powerful skills and extra capabilities to your agents. |
  ```

- [ ] **Step 2: Update Codex installation instructions comment**
  Find line 139:
  ```markdown
  # superpowers requires manual install via /plugins in the Codex CLI
  ```
  Change to:
  ```markdown
  # superpowers: run /plugins inside Codex CLI to install manually
  ```

---

### Task 4: Update README.ko.md Optional Skills Table and Codex Guide

**Files:**
- Modify: `README.ko.md`

- [ ] **Step 1: Update superpowers row in table**
  Find line 113:
  ```markdown
  | **superpowers** | Claude Code, agy | 추천 | 에이전트에 강력한 스킬과 추가 기능을 플러그인으로 설치. |
  ```
  Change to:
  ```markdown
  | **superpowers** | Claude Code, agy, Codex | 추천 | 에이전트에 강력한 스킬과 추가 기능을 플러그인으로 설치. |
  ```

- [ ] **Step 2: Update Codex installation instructions comment**
  Find line 139:
  ```markdown
  # superpowers는 Codex CLI 내에서 /plugins 명령어를 통해 수동 설치해야 합니다.
  ```
  Change to:
  ```markdown
  # superpowers: Codex CLI 내에서 /plugins 명령어를 실행하여 수동으로 설치
  ```

---

### Task 5: Update Memory and Run Quality Gate

**Files:**
- Modify: `.notes/memory.md`

- [ ] **Step 1: Add new entry to memory.md**
  Add a section for today's date and detail the removal of the redundant TDD skill.
  
- [ ] **Step 2: Run verification script**
  Run: `bash -n install.sh uninstall.sh scripts/*.sh`
  Expected: Command exits successfully.

---

### Task 6: Commit and Push Changes

- [ ] **Step 1: Add changes to Git staging area**
  Run: `git add -A`
  Expected: All modified/deleted files staged.

- [ ] **Step 2: Commit**
  Run: `git commit -m "chore: remove tdd skill (redundant with superpowers), recommend skills for all agents"`
  Expected: Commit successfully created.

- [ ] **Step 3: Push**
  Run: `git push`
  Expected: Changes pushed to remote repository.
