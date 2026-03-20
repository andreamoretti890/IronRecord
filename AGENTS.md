# IronRecord Agent Guide

## Project Overview
IronRecord is an offline-first iOS gym logging app.
- UI: SwiftUI
- Persistence: SwiftData (local only, no sync)
- Target: iOS 26 (beta — treat all APIs as potentially undocumented;
  prefer explicit skill lookups over training-data assumptions)
- Language: Swift 6, strict concurrency

---

## Domain Boundaries
- `Exercise`: canonical movement catalog entry.
- `WorkoutTemplate`: reusable workout definition.
- `TemplateExercise`: ordered exercise prescription within a template.
- `TemplateExerciseSet`: per-set template prescription metadata.
- `TemplateSetType`: set types.

---

## Hard Constraints
- iOS 26 minimum deployment target — no iOS 17/18 fallbacks.
- No network dependency — app must be fully functional offline.
- Seed must be idempotent: safe to re-run on every launch.
- Seed must backfill missing entities in partially initialized stores.
- Prefer additive SwiftData migrations; never break existing user data.
- Do not introduce `@StateObject` or `ObservableObject` — use `@Observable`.

---

## Working Rules
1. New screens → `IronRecord/Features/<FeatureName>/`
2. Model changes → `IronRecord/Models/` first, then update seed if needed
3. Seed changes → `IronRecord/Seed/SeedData.swift`
4. Names must be explicit and domain-oriented: `WorkoutTemplate`, not `TemplateManager`
5. Split files by responsibility — no God files
6. Every user-facing SwiftUI view needs a `#Preview` with multiple states
   (empty, populated, loading/error if applicable)

---

## Skills - How to use
> **Rule: Always read the skill file fully before writing any code
> related to that skill's domain. Do not rely on training-data patterns
> for SwiftUI or SwiftData — the skill files encode the correct patterns
> for this project.**

### Skill Reference

| Skill                  | Read When...                                                                 |
|------------------------|------------------------------------------------------------------------------|
| `swiftui-expert-skill` | Starting any SwiftUI task. Load this first, always.                          |
| `swiftui-patterns`     | After `swiftui-expert-skill`, for structural layout or view composition.     |
| `swiftdata`            | Any read/write/query/migration/model change involving SwiftData.             |
| `swiftui-navigation`   | Touching `NavigationStack`, sheets, `.navigationDestination`, tabs, links.   |
| `swiftui-gestures`     | Implementing swipe, drag, long-press, or any `Gesture` type.                 |

### Skill Load Order (most common combos)
- **New feature screen**: `swiftui-expert-skill` → `swiftui-patterns` → `swiftui-navigation`
- **Model + view change**: `swiftdata` → `swiftui-expert-skill`
- **Gesture on a list row**: `swiftui-expert-skill` → `swiftui-gestures`
- **API migration**: `swiftui-expert-skill` first, check SosumiMCP for diffs

---

## MCP Servers

### XcodeBuildMCP — Build & Validate
Use XcodeBuildMCP to compile and validate code. Do not guess whether code compiles.

**When to use:**
- After implementing or modifying any Swift file
- After a SwiftData model change
- Before declaring a task complete

**Workflow:**
1. Run the build tool targeting the `IronRecord` scheme, iOS 26 simulator
2. If build fails:
   - Read the full error output
   - Fix all errors (not just the first)
   - Rebuild — repeat until clean
3. A task is not done until the build is clean

**Do not:**
- Skip the build step and assume code is correct
- Declare success with unresolved warnings that look like errors

### SosumiMCP — Apple API Reference
SosumiMCP provides up-to-date Apple SDK documentation and API diffs.
Use it when you are uncertain about an API's availability, signature, or
behavior on iOS 26 — especially for SwiftUI and SwiftData, which changed
significantly in recent OS versions.

**When to use:**
- Before using any SwiftUI or SwiftData API that may have changed post-iOS 17
- When XcodeBuildMCP returns a "no such modifier/method" or deprecation error
- When proposing a modern API migration (check the diff first)
- When seed or migration logic touches SwiftData schema versioning APIs

**Workflow:**
- Query SosumiMCP for the specific symbol or feature
- Confirm availability on iOS 26
- Then write the code

---

## Definition of Done for New Features
A task is complete when **all** of the following are true:

- [ ] XcodeBuildMCP build passes cleanly (zero errors) for iOS 26
- [ ] Feature is reachable from existing root navigation
- [ ] Empty-state UI is handled
- [ ] Offline behavior is preserved (no network calls introduced)
- [ ] If persistence is in scope: reads/writes go through SwiftData models only
- [ ] SwiftUI previews exist with at least two states (empty + populated)
- [ ] Seed remains idempotent if new core entities were added

---

## Common Pitfalls (Do Not Do These)
- Do not use `@StateObject` / `ObservableObject` — use `@Observable` macro
- Do not duplicate SwiftData model data into separate in-memory structs
- Do not add network calls — this app is fully offline
- Do not add a new `NavigationStack` inside a feature that is already inside one
- Do not write SwiftData queries outside of a `@Query` property or explicit
  `ModelContext` fetch — no raw container access in views
- Do not overcomplicate things
