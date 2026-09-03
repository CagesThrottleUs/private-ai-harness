---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Narration:** between steps, narrate at most one short line — tool results carry the record.

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

### Step 0: Durable Progress Check

Before anything else, check for a ledger:
`cat "$(git rev-parse --git-path executing-plans)/progress.md"` (ignore errors if absent).
Tasks listed there as complete are DONE — do not re-execute; resume at the first incomplete task.
Conversation memory does not survive compaction; the ledger is your recovery map.

### Step 1: Load and Review Plan
1. Read plan file; note the `## Global Constraints` section — these bind every task
2. Pre-flight: scan for tasks that contradict each other or the Global Constraints.
   If conflicts found, raise as ONE batched question before execution begins.
3. Review for other concerns; raise with partner if any
4. If clean: create todos and proceed

### Step 2: Execute Tasks

For each task:
1. Extract task brief: `skills/subagent-driven-development/scripts/task-brief PLAN_FILE N`
   — read the printed file path; do not paste task text into context
2. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Before committing: run the `design-principles` **Review Checklist** — catch violations before they land
5. Before committing: apply `karpathy` lens — no speculative code, surgical changes only, every changed line traces to the spec
6. Before committing: apply `code-documentation` to every public construct written — full docstring, `@spec_id`, `@req_id`
7. Run linter gate: detect language from manifest, run format check + lint + type check. Zero issues required.
8. If task creates a component with external dependencies (DB, queue, cache, external HTTP): invoke `integration-testing` skill — write Testcontainers-based integration tests alongside unit tests
8. If task created a new API endpoint or service component: invoke `observability-standards` — instrument logging, metrics, SLOs, alerts, runbooks before this endpoint is deployed
9. Mark as completed
10. Append to ledger: `echo "Task N: complete" >> "$(git rev-parse --git-path executing-plans)/progress.md"`

### Step 3: Complete Development

After all tasks complete and verified:
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- That skill starts with a wiki sync check (Step 0) — ensure all behavior changes are documented in `wiki/` before tests run
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
- **superpowers:design-principles** - Review Checklist run before each task commit (DRY, KISS, YAGNI, SOLID, GoF)
- **superpowers:karpathy** - Anti-pattern lens run before each task commit (no speculation, surgical changes, verifiable criteria)
- **superpowers:code-documentation** - Document every public construct before committing (spec_id, req_id, full docstring)
- **integration-testing** - After any task creating a component with external dependencies — Testcontainers-based integration tests alongside unit tests
- **observability-standards** - After any task that creates an API endpoint or service component — instrument logging, golden signal metrics, SLOs, alert rules, and runbooks
