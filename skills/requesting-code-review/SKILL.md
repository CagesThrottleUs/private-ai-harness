---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging. Routes to the right review agent(s) based on context. For full suite use /review all. For targeted review use /review <type>.
---

# Requesting Code Review

Route to the right review agent(s) for what you've built. Reviews are mandatory before merge — the type and depth depend on what changed.

**Core principle:** Review early, review often. After each task, not just at PR time.

---

## Review Agent Roster

| Agent | Invocation | Use when |
|-------|-----------|----------|
| `pr-reviewer` | `/review pr` | Every PR, always. 5 dimensions (code quality, docs, security, reliability, performance) + traceability. Blocks without spec. |
| `spec-impl-reviewer` | `/review spec` | You have a spec and want to verify the implementation actually satisfies acceptance criteria — not just that annotations exist. |
| `test-quality-reviewer` | `/review tests` | Tests were added or modified. Checks meaningful assertions, spec TC coverage, mutation resistance, anti-patterns. |
| `security-reviewer` | `/review security` | PR touches auth, input handling, data access, external communication, config, or adds new endpoints/handlers. |
| `full-project-reviewer` | `/review full` | Before releases, after major milestones, full codebase audit. Not per-PR. |
| **All at once** | `/review all` | Before any merge. Runs all four PR-scoped agents in parallel. |

---

## When to Use Which

### Minimum (every PR)
```
/review pr
```

### Standard (recommended for all feature PRs)
```
/review all
```
Runs pr-reviewer + spec-impl-reviewer + test-quality-reviewer + security-reviewer in parallel.

### After each task (during subagent-driven development)
```
/review pr
```
Catch issues before they compound. Fix before moving to next task.

### Before merge (mandatory)
```
/review all
```
All four agents. Aggregated report. No merge if any Critical finding.

### Full codebase audit (periodic)
```
/review full
```
Not per-PR. Use after significant milestones or before production releases.

---

## How to Request

**Quick (most common):**
```
/review all
```
The `review` skill collects inputs, dispatches all agents in parallel, aggregates results.

**Targeted:**
```
/review security      ← just security
/review spec          ← just spec correctness
/review tests         ← just test quality
```

**Direct from chat:**
- "review my PR" → routes to `/review pr`
- "does this satisfy the spec" → routes to `/review spec`
- "check my tests" → routes to `/review tests`
- "security review" → routes to `/review security`

---

## Act on Feedback

| Severity | Action |
|----------|--------|
| Critical | Fix immediately before any other work |
| Important | Fix before merge — do not proceed |
| Minor | Note for later, address when possible |

Push back if reviewer is wrong — with technical reasoning and evidence.

---

## Self-Check Before Requesting

Before routing to any review agent, run the `design-principles` **Review Checklist**. Sending a design-violated diff multiplies review cost — fix structural violations first.

See `design-principles/SKILL.md` → Review Checklist.

## Integration

- **Subagent-driven development:** `/review pr` after each task
- **pr-creator:** runs `/review all` automatically before creating PR (Step 5)
- **finishing-a-development-branch:** runs `/review all` before merge/PR options
- **Ad-hoc:** `/review <type>` any time during development

See `review/SKILL.md` for the full orchestration logic.
