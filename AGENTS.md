# IronRecord Agent Guide

## Objective
- Build an offline-first iOS app for logging gym progress.
- Use SwiftUI for UI and SwiftData for local persistence.
- Keep the first version intentionally small: starter exercise library, workout templates, routines, and real session execution/logging.

## Codebase Map
- `IronRecord/IronRecordApp.swift`: app entry point and SwiftData container registration.
- `IronRecord/ContentView.swift`: tab shell and first-launch seed trigger.
- `IronRecord/Models/`: SwiftData entities (domain layer).
- `IronRecord/Seed/SeedData.swift`: idempotent starter data seeding.
- `IronRecord/Features/Home/`: dashboard and high-level metrics.
- `IronRecord/Features/Templates/`: template browsing and prescriptions.
- `IronRecord/Features/Templates/TemplateEditorView.swift`: create/edit template form UI.
- `IronRecord/Features/Templates/TemplateDraft.swift`: temporary draft model used by editor screens.
- `IronRecord/Features/Templates/TemplateExercisePickerView.swift`: searchable multi-select exercise picker for template editing.
- `IronRecord/Features/Routines/`: weekly routine planning views.
- `IronRecord/Features/Sessions/`: start/resume/completed session list and workout creation.
- `IronRecord/Features/Logger/StartWorkoutView.swift`: template picker to begin a workout.
- `IronRecord/Features/Logger/ActiveWorkoutView.swift`: in-progress workout logging UI.

## Architecture (Minimal, Scalable)
- Pattern: feature-first SwiftUI over shared SwiftData models.
- Data flow:
  - Views read with `@Query`.
  - Feature views write through `modelContext`.
  - No separate repository/service layer unless complexity requires it.
- Keep models as the source of truth; avoid duplicating state in view-only structs.

## Domain Boundaries
- `Exercise`: canonical movement catalog entry.
- `WorkoutTemplate`: reusable workout definition.
- `TemplateExercise`: ordered prescription for each template.
- `Routine`: named weekly split (e.g., PPL, Upper/Lower).
- `RoutineDay`: routine schedule entry that links to a template.
- `WorkoutSession`: performed workout snapshot (`endedAt == nil` means in progress, non-`nil` means completed).
- `SetEntry`: per-set performance data, including ordering metadata for workout execution:
  - `setNumber`
  - `exercisePosition`
  - `targetRepsSnapshot`

## Current Product Behavior (Milestone 1)
- User starts a workout from a seeded template.
- Session creates pre-generated set rows from `targetSets`.
- Required input to finish: `reps > 0` for all sets.
- Default weight unit shown in logger: `kg`.
- Sessions can be resumed after app relaunch while `endedAt` is `nil`.

## Current Product Behavior (Templates CRUD)
- Templates tab supports create, edit, and delete flows.
- Template creation/editing uses a form with exercise-level prescriptions (`sets`, `target reps`, `rest`, `notes`).
- Adding exercises in editor uses a searchable, category-grouped, multi-select picker.
- Delete uses confirmation and warns when the template is referenced by routine days.
- Template names are unique (case-insensitive check in UI + model-level uniqueness).
- Empty template rep targets are allowed; workout logging still requires performed reps to finish sessions.

## Constraints
- Minimum deployment target is iOS 26.
- App must function without network connectivity.
- Seed operation must remain idempotent and safe to run on each launch.
- Seed must backfill missing starter entities in partially-initialized stores (do not gate seeding on only one table/entity count).
- Prefer additive migrations; do not break existing user workout history.
- Keep baseline screens functional before adding advanced UX.

## Working Rules
- Add new screens under `IronRecord/Features/<FeatureName>/`.
- Add shared model changes under `IronRecord/Models/` first.
- Update `IronRecord/Seed/SeedData.swift` when introducing core entities needed for first-run UX.
- Keep naming explicit and domain-oriented (`WorkoutTemplate`, not `TemplateManager`).
- Include lightweight previews for each new SwiftUI view.
- Preserve additive data evolution for SwiftData models; avoid destructive field changes.
- Keep workout history immutable enough for analytics: use snapshot fields instead of live template references for historical display.

## Fast Path (Where To Edit First)
- Start/resume/finish flow: `IronRecord/Features/Sessions/SessionsView.swift`
- Active logging UI + autosave: `IronRecord/Features/Logger/ActiveWorkoutView.swift`
- Session generation logic from templates: `IronRecord/Features/Sessions/SessionsView.swift`
- Template CRUD list/detail actions: `IronRecord/Features/Templates/TemplatesView.swift`
- Template editor form UI: `IronRecord/Features/Templates/TemplateEditorView.swift`
- Template multi-select exercise picker: `IronRecord/Features/Templates/TemplateExercisePickerView.swift`
- Template editor draft structure: `IronRecord/Features/Templates/TemplateDraft.swift`
- Dashboard counts and recent workouts: `IronRecord/Features/Home/HomeView.swift`
- Model evolution: `IronRecord/Models/WorkoutSession.swift`

## Manual Verification Commands
- Build:
  - `xcodebuild -project IronRecord.xcodeproj -scheme IronRecord -destination 'generic/platform=iOS' -derivedDataPath /tmp/IronRecordDerivedData build CODE_SIGNING_ALLOWED=NO`

## Definition of Done for New Features
- Compiles cleanly for iOS 26 target.
- Persists data correctly using SwiftData.
- Is reachable from existing navigation/tabs.
- Handles empty-state UI.
- Preserves offline behavior.
