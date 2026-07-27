---
name: android-advisor
description: >
  Use for any Android, Kotlin, Jetpack Compose, or Compose Multiplatform work when
  several overlapping global Android skills are installed. Resolves which installed
  specialist wins for each sub-task and in what order, so the agent gets one
  coherent answer instead of four contradictory ones. The engineer router activates
  this overlay inside each construct/test/verify step on Android work.
---

# Android Advisor

First instance of the `domain-overlay` pattern. This overlay owns **which
installed Android skill the agent consults** for each sub-task, and in what order
across an engineer lane. It carries no Android knowledge itself — it routes to the
skills that do, and states why each wins so ties break cleanly.

**Announce at start:** "Activating android-advisor to route Android skills."

> Read `skills/domain-overlay/SKILL.md` for the pattern and the reusable
> precedence heuristics this instance follows.

## 1. Detection signals

Activate this overlay when the task or working tree shows any of:

- `.kt` / `.kts` source files, or `build.gradle` / `build.gradle.kts`
- `@Composable`, `androidx.*`, `AndroidManifest.xml`
- explicit mention of Android, Kotlin, Jetpack Compose, KMP/CMP, Gradle, Hilt/Koin

## 2. Precedence table

Assumes the full installed set (chrisbanes, aldefy, rcosteira79, silvermoon,
skydoves-testing, skydoves-perf, Meet-Miyani, Drjacky, hamen, ceorkm, baoyu).
Every row states the tie-break **reason** — that reason is what the agent uses to
avoid blending contradictory skills.

| Sub-task | PRIMARY | Support / verify | Tie-break reason |
|---|---|---|---|
| Compose UI: state, recomposition, side-effects, modifiers, slot APIs, testing patterns | **chrisbanes/skills** | aldefy `compose-expert` = confirm an androidx API/signature exists | chrisbanes = sole authority on Compose idioms; aldefy is a fact-checker only, never dictates style |
| Kotlin language: coroutines, flow, structured concurrency, value classes, KMP expect/actual | **chrisbanes/skills** | rcosteira79 `kotlin-coroutines` / `kotlin-flows` for app-level wiring | authoring idioms vs app-wiring; use chrisbanes for language shape, rcosteira for how it plugs into the app |
| Architecture, DI, data layer, networking, gradle, modularization | **rcosteira79/android-skills** | silvermoon for its **unique** skills only: `android-viewmodel`, `xml-to-compose-migration`, `rxjava-to-coroutines-migration`, `android-accessibility`, `android-emulator` | shared dir (coil, retrofit, coroutines, data-layer, gradle-perf) → rcosteira wins on recency; silvermoon fires only for skills rcosteira lacks |
| Tests: unit, Compose UI, instrumented, ADB, CI screenshots | **skydoves/android-testing-skills** | — | sole testing authority for this domain |
| Performance/stability: recomposition profiling, baseline profiles, R8, strong-skipping, CI stability enforcement | **skydoves/compose-performance-skills** | chrisbanes `compose-stability-diagnostics` at authoring time | measurement vs authoring — skydoves-perf measures/profiles/enforces; chrisbanes fixes stability while writing. Sequence, do not blend |
| Compose Multiplatform / shared module + MVI | **Meet-Miyani/compose-skill** | — | scope guard: fires only when target is a CMP/shared module, not a plain Android module |
| Navigation3 + module conventions | **Drjacky/claude-android-ninja** | — | scope guard: fires only if the repo actually uses Navigation3 |
| UI/UX mockups, visual/screen design | **ceorkm/mobile-app-ui-design** | jimliu `baoyu` for polished HTML mockups | design phase only — never let a design skill drive Kotlin code |
| Pre-PR self-audit of Compose code | **hamen/compose_skill** | — | evidence-based audit; runs before review, catches smells before a reviewer does |

**Suppression rules (state these when two skills both fire):**
- chrisbanes outranks aldefy, Meet-Miyani, and Drjacky on Compose *idioms*.
- For any dir present in both rcosteira79 and silvermoon, use rcosteira79; ignore
  the silvermoon twin. silvermoon contributes only its five unique skills above.
- skydoves-perf and chrisbanes stability are ordered, not rival — never run both
  as "how to structure this code" in the same breath.

## 3. Lane-step mapping (engineer)

Where each survivor fires inside an engineer lane:

| Lane step | Android skill(s) |
|---|---|
| `codebase-comprehension` | rcosteira79 (architecture map); silvermoon `android-viewmodel` if MVVM |
| design / mockups (UI features) | ceorkm, baoyu — mockups only |
| TDD **GREEN** (write code) | chrisbanes (Compose + Kotlin) + rcosteira79 (wiring); aldefy to verify an androidx API before use |
| TDD **test** | skydoves-testing |
| perf-sensitive code | skydoves-perf + chrisbanes stability-diagnostics |
| KMP / Nav3 modules | Meet-Miyani / Drjacky as their scope guards allow |
| `verification-before-completion` | **hamen audit** (Android pre-review gate) → then perf check with skydoves-perf |

## 4. Pre-review audit gate

Before `requesting-code-review` / `/review`, run **hamen/compose_skill** as the
Android self-audit, then a **skydoves-perf** stability pass on any changed
`@Composable`. Fix findings first. This is the gate that keeps the human reviewer
and QE from finding what the agent could have caught — the whole reason this
overlay exists.
