# IronRecord Agent Guide

## Objective
- Build an offline-first iOS app for logging gym progress.
- Use SwiftUI for UI and SwiftData for local persistence.
- Current scope covers reusable workout templates and in-progress workout session tracking.

## Architecture (Minimal, Scalable)
- Pattern: feature-first SwiftUI over shared SwiftData models.
- Data flow:
  - Views read persisted data with `@Query`.
  - Feature views write through `modelContext` and save explicitly after mutations.
  - Keep transient UI state local to the feature view that owns the interaction.
- Keep models as source of truth; avoid duplicating persisted data in parallel model layers.

## Domain Boundaries
- `Exercise`: canonical movement catalog entry.
- `WorkoutTemplate`: reusable workout definition.
- `TemplateExercise`: ordered exercise prescription within a template.
- `TemplateExerciseSet`: per-set template prescription metadata.
- `WorkoutSession`: an in-progress or finished workout created from a template.
- `WorkoutSessionExercise`: exercise snapshot inside a session.
- `WorkoutSessionSet`: per-set planned and actual workout data inside a session.

## Current Product Behavior
- App opens directly into Templates.
- Seed data backfills starter exercises and starter templates on launch.
- Templates are persisted with SwiftData and support create, edit, duplicate, and delete flows.
- Template editing supports:
  - Editable title.
  - Add/remove/replace exercises.
  - Exercise notes, rest timer editing, and per-set prescription editing.
  - Save disabled until title is non-empty and at least one exercise exists.
  - Interactive swipe-to-dismiss disabled for template forms.
- Exercise picker supports:
  - Search with initial focus.
  - Multi-select and add selected exercises.
  - Filters for body part, equipment, and mode (mode is filter-only, not shown in rows).
- Starting a template creates a persisted `WorkoutSession` and navigates into the active workout flow.
- If a workout is already active, the user can resume it or discard it before starting another one.
- Active workout UI supports:
  - Live elapsed-time header.
  - Per-set logging with planned vs actual values.
  - Adding and deleting extra sets.
  - Finish and discard flows with persistence.

## Constraints
- Minimum deployment target is iOS 26.
- App must function without network connectivity.
- Seed operation must remain idempotent and safe to run on each launch.
- Seed must backfill missing starter entities in partially initialized stores.
- Prefer additive migrations; do not break existing user template/exercise data.
- Preserve active workout data unless the user explicitly discards it.

## Working Rules
- Add new screens under `IronRecord/Features/<FeatureName>/`.
- Add shared model changes under `IronRecord/Models/` first.
- Update `IronRecord/Seed/SeedData.swift` when introducing core entities needed for first-run UX.
- Keep naming explicit and domain-oriented (`WorkoutTemplate`, not `TemplateManager`).
- Include lightweight previews for user-facing SwiftUI screens.
- Keep feature files split by responsibility instead of collapsing templates or session flows into one file.

## Skills
- Use `swiftui-pro` for any task that reads, writes, reviews, or refactors SwiftUI views in this repo.
- Use `swiftui-pro` when touching navigation, sheets, alerts, forms, lists, accessibility, animations, or SwiftUI performance behavior.
- Use `swiftui-pro` before proposing modern SwiftUI API migrations or non-trivial UI structure changes.
- Skip `swiftui-pro` only for tasks that are strictly non-UI, such as pure SwiftData model changes, seed data updates, or repo documentation with no SwiftUI impact.

## Manual Verification Commands
- Build:
  - `xcodebuild -project IronRecord.xcodeproj -scheme IronRecord -destination 'generic/platform=iOS' -derivedDataPath /tmp/IronRecordDerivedData build CODE_SIGNING_ALLOWED=NO`

## Definition of Done for New Features
- Compiles cleanly for iOS 26 target.
- Is reachable from existing root navigation.
- Handles empty-state UI.
- Preserves offline behavior.
- If persistence is in scope, writes/reads through SwiftData correctly.
- If workout execution is in scope, active-session resume/discard behavior remains coherent.
