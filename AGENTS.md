# IronRecord Agent Guide

## Objective
- Build an offline-first iOS app for logging gym progress.
- Use SwiftUI for UI and SwiftData for local persistence.
- Current scope is templates-first: iterate quickly on template browsing/creation UX before expanding to routines/sessions.

## Codebase Map
- `IronRecord/IronRecordApp.swift`: app entry point and SwiftData container registration.
- `IronRecord/ContentView.swift`: root `NavigationStack` and first-launch seed trigger.
- `IronRecord/Models/Exercise.swift`: canonical exercise catalog model.
- `IronRecord/Models/WorkoutTemplate.swift`: template models (`WorkoutTemplate`, `TemplateExercise`, `TemplateExerciseSet`).
- `IronRecord/Seed/SeedData.swift`: idempotent starter data seeding.
- `IronRecord/Features/Templates/TemplatesView.swift`: templates list screen + add/delete presentation.
- `IronRecord/Features/Templates/TemplateRowView.swift`: template row UI and temporary row model (`TemplateRowItem`).
- `IronRecord/Features/Templates/AddTemplateView.swift`: add-template form and save validation.
- `IronRecord/Features/Templates/TemplateExercisePickerView.swift`: searchable multi-select picker.
- `IronRecord/Features/Templates/TemplateExerciseFilters.swift`: filter/value models and inference helpers.
- `IronRecord/Features/Templates/TemplateExerciseFilterViews.swift`: reusable filter chip and filter selection sheet UI.

## Architecture (Minimal, Scalable)
- Pattern: feature-first SwiftUI over shared SwiftData models.
- Data flow:
  - Views read with `@Query` when persistence data is needed.
  - Feature views write through `modelContext` when persistence is enabled.
  - Keep lightweight UI-only state local to feature views while iterating on UX.
- Keep models as source of truth; avoid duplicating persisted data in parallel model layers.

## Domain Boundaries
- `Exercise`: canonical movement catalog entry.
- `WorkoutTemplate`: reusable workout definition.
- `TemplateExercise`: ordered exercise prescription within a template.
- `TemplateExerciseSet`: per-set template prescription metadata.

## Current Product Behavior (Templates Focus)
- App opens directly into Templates.
- Template list is currently UI-only and backed by local mock rows.
- User can create a template via sheet:
  - Editable title.
  - Add/remove exercises.
  - Save disabled until title is non-empty and at least one exercise exists.
  - Interactive swipe-to-dismiss is disabled for the add-template sheet.
- Exercise picker supports:
  - Search with initial focus.
  - Multi-select and add selected exercises.
  - Filters for body part, equipment, and mode (mode is filter-only, not shown in rows).
- Delete is available from each template row menu with alert confirmation.

## Constraints
- Minimum deployment target is iOS 26.
- App must function without network connectivity.
- Seed operation must remain idempotent and safe to run on each launch.
- Seed must backfill missing starter entities in partially initialized stores.
- Prefer additive migrations; do not break existing user template/exercise data.

## Working Rules
- Add new screens under `IronRecord/Features/<FeatureName>/`.
- Add shared model changes under `IronRecord/Models/` first.
- Update `IronRecord/Seed/SeedData.swift` when introducing core entities needed for first-run UX.
- Keep naming explicit and domain-oriented (`WorkoutTemplate`, not `TemplateManager`).
- Include lightweight previews for user-facing SwiftUI screens.
- Keep templates feature split by responsibility (list, row, add flow, picker, filters).

## Fast Path (Where To Edit First)
- Templates list actions/presentation: `IronRecord/Features/Templates/TemplatesView.swift`
- Template row UI/actions menu: `IronRecord/Features/Templates/TemplateRowView.swift`
- Add-template flow + validation: `IronRecord/Features/Templates/AddTemplateView.swift`
- Exercise picker flow: `IronRecord/Features/Templates/TemplateExercisePickerView.swift`
- Filter models + inference rules: `IronRecord/Features/Templates/TemplateExerciseFilters.swift`
- Filter UI components: `IronRecord/Features/Templates/TemplateExerciseFilterViews.swift`
- Seed/backfill behavior: `IronRecord/Seed/SeedData.swift`
- Model evolution: `IronRecord/Models/WorkoutTemplate.swift`

## Manual Verification Commands
- Build:
  - `xcodebuild -project IronRecord.xcodeproj -scheme IronRecord -destination 'generic/platform=iOS' -derivedDataPath /tmp/IronRecordDerivedData build CODE_SIGNING_ALLOWED=NO`

## Definition of Done for New Features
- Compiles cleanly for iOS 26 target.
- Is reachable from existing root navigation.
- Handles empty-state UI.
- Preserves offline behavior.
- If persistence is in scope, writes/reads through SwiftData correctly.
