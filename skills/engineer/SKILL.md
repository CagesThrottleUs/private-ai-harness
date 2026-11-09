---
name: engineer
description: >
  Front door to the harness catalogue of skills and subagents. Invoke as
  /engineer to browse the catalogue, /engineer <job> (understand, define,
  design, build, test, review, ship, measure, learn) to see one group,
  /engineer <tool> to run that skill or subagent directly, or /engineer
  <request> to have the best-fitting tools picked for a problem. A library, not
  a pipeline: a tool runs only when it fits what was asked.
user-invocable: true
---

# /engineer — the harness catalogue

The harness is a library of tools, not a pipeline. The user picks tools, or
describes a problem and lets you pick. Nothing chains on its own. The user owns
the result: every tool exists to sharpen their understanding of the problem,
not to replace it.

`catalogue.md` in this skill's directory lists every skill and subagent,
grouped by the job it does. Read it before choosing.

## Usage

| The user types | You do |
|---|---|
| `/engineer` or `/engineer catalogue` | Show each job heading with its tool names and one line per tool |
| `/engineer <job>` (e.g. `test`, `review`) | Show that job's tools in full, subagents included |
| `/engineer <tool> [args]` | Use exactly that skill or subagent |
| `/engineer <request>` | Pick tools for the request, as below |

## Picking tools for a request

1. **Name the job.** Say what the request needs: understand, learn, define,
   design, build, test, review, ship, or measure. One request can span two.
2. **Pick the fewest tools that do it**, usually one or two. For each, one
   line: tool, why it fits, what it produces. When the choice was close, name
   the runner-up and why you passed on it.
3. **Do what was asked, no more.** Don't add stages the request didn't ask
   for (a design doc, CI setup, load tests, a readiness review) just because
   one tool usually comes before or after another.
4. **Treat prerequisites as advice.** A tool may say it works best after
   another. If that hasn't happened, tell the user what the earlier tool
   would have caught and ask: run it first, or continue? If nobody can
   answer, continue and list the gap at the top of your output.
5. **Suggest, don't chain.** When a tool finishes, name the one or two tools
   that would plausibly come next and why. The user decides.
6. **Domain overlay.** If the files match a `<domain>-advisor`'s detection
   signals, read that advisor first; it decides which of the overlapping
   installed skills to use for each sub-task. Today that is `android-advisor`
   (`.kt`, `.kts`, `build.gradle(.kts)`, `@Composable`, `androidx.*`).
7. **Nothing fits?** Externally installed skills might; check the host's
   skill list. If a need keeps recurring with no tool for it, use
   `writing-skills` to create one.

## Running a subagent

Subagents are reviewers with explicit inputs; the catalogue lists each one's
required inputs. Dispatch by host:

| Host | Name |
|---|---|
| Claude Code | `private-ai-harness:<name>` via the Agent tool |
| Codex, opencode, Copilot | `private-ai-harness-<name>` |

Pass every required input. Pass `REPORT_FILE` to keep long findings out of the
conversation; read the verdict first, then the file if needed.

## Working stance

- **Explain so the user can re-explain.** Use plain words, one idea at a time,
  and evidence for every claim (`file:line`, versioned docs, numbers with their
  basis). If the user couldn't teach it to someone else from your explanation,
  you aren't done.
- **When checking the user's own reasoning or code, point and ask.** Say where
  it breaks and ask why; give the fix only when asked. In Anthropic's 2026
  randomized trial, developers who leaned on AI to debug their code scored 24%
  on a follow-up comprehension quiz. Those who asked conceptual questions, or
  questioned generated code until they understood it, scored 65–86%
  ([source](https://www.anthropic.com/research/AI-assistance-coding-skills)).
- **Let them predict first.** Before revealing a test result, a root cause, or
  a review verdict that the user is reasoning about, give them the chance to
  say what they expect. Scored predictions are how judgment gets calibrated.
- `teacher` is the tool for deliberately checking and deepening understanding.

## Keeping the catalogue true

Adding, renaming, or removing a skill or agent means updating `catalogue.md`
in the same commit. Run `python3 scripts/catalogue-check` from this directory;
it exits 0 when the catalogue matches the skills and agents on disk.
