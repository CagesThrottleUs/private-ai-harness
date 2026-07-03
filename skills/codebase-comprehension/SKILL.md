---
name: codebase-comprehension
description: >
  Understand a codebase area before making any change. Maps relevant symbols, callers,
  call chains, data flow, and dependencies using whatever structural tools the repo has —
  codegraph or Scout when indexed, LSP / ctags / ripgrep as portable fallback.
  Invoke before touching code in any engineering lane. Inline summary for quick-fix;
  comprehension.md artifact for task and epic.
user-invocable: true
---

# Codebase Comprehension

Understand before you change. Maps the relevant area structurally — what exists, what calls what, what owns what, what would break. Output is a confirmed map the next phase reads.

## Depth by lane

| Lane | Depth | Artifact |
|---|---|---|
| quick-fix | 1–3 codegraph calls, inline | none |
| task | Full area map | `.ai/work/<id>/comprehension.md` |
| epic | Subsystem-wide map | `.ai/work/<id>/comprehension.md` |
| research | Inline, area being evaluated | none |

## Process

### 1 — Identify the target area

From the request extract: symbol names, file paths, feature names, system area. If none are obvious, ask one question: "Which part of the codebase should I start from?"

### 2 — Map with structural tools (prefer structural over grep)

Comprehension needs five operations. Use the best tool the repo actually has — never hard-depend on one index that may not exist (Scout/codegraph are not open-source and vanish when you switch orgs):

| Operation | Best (indexed) | Portable fallback |
|---|---|---|
| Locate symbol | `codegraph_search` / Scout `search` | LSP `go_to_definition`, `ctags`, `rg "\b<sym>\b"` |
| Who calls this | `codegraph_callers` / Scout `find_references` | LSP find-references, `rg` for call sites |
| What this calls | `codegraph_callees` / Scout `explain_symbol` | read the body, `rg` on invoked names |
| Blast radius | `codegraph_impact` / Scout `impact` | callers-of-callers via repeated find-references |
| Explore an area | `codegraph_explore` / Scout `investigate` | `file_outline` + directory read + `rg` |

Prefer an indexed tool when present — one call, AST-accurate. If none is indexed, drop to LSP → ctags/tree-sitter → ripgrep. The operation is what matters, not the tool. Stop when the picture is clear.

**For a bug:** broken symbol + its callers (what currently depends on broken behavior).
**For a feature:** extension point (where new code plugs in) + adjacent patterns in the same area.
**For an epic:** all entry points of the system area; explore several names at once.

Do NOT re-verify an indexed result with grep — the AST parse is more accurate. Grep is a fallback when no index exists, not a double-check.

### 3 — Extract key facts

From the map, identify:

- **Entry points:** how requests/events arrive at this area
- **Key symbols:** the 3–7 most relevant functions/classes (file:line — one line on what each does)
- **Dependencies:** external things this area touches (DB tables, APIs, queues, configs)
- **Invariants:** visible constraints — error handling patterns, auth guards, size limits
- **Blast radius:** what changes to this area would break (from the blast-radius operation above)
- **Assumptions:** anything inferred, not confirmed — flag these explicitly

### 4 — Present and confirm

Output:

```
Comprehension: [area name]

Entry points:
  [how requests arrive]

Key symbols:
  [file:line] — [what it does]
  ...

Dependencies:
  [DB tables, APIs, queues]

Invariants:
  [constraints visible in code]

Blast radius:
  [what changes here would affect]

Assumptions (verify these):
  [anything inferred, not confirmed]
```

Ask: **"Does this match your understanding, or did I miss something?"**

Correct any misunderstanding before the next phase starts. A wrong map produces wrong code.

### 5 — Write artifact (task/epic only)

Write the confirmed comprehension to `.ai/work/<id>/comprehension.md`. Downstream phases (brainstorming, writing-plans) read this file instead of re-doing structural analysis.

## What this is NOT

- Not a code review — that is `requesting-code-review`
- Not a debugging session — that is `systematic-debugging`
- Not a design exercise — that is `brainstorming`
- Not an exhaustive grep of the whole repo — targeted structural map only

It is a map. Make one before you build.
