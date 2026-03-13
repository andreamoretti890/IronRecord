import SwiftData
import SwiftUI

struct WorkoutSessionExerciseCard: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Exercise.name) private var availableExercises: [Exercise]

    let session: WorkoutSession
    let exercise: WorkoutSessionExercise
    let isPaused: Bool
    let onSave: () -> Void
    let onToggleDone: (WorkoutSessionSet, Bool) -> Void

    @State private var notesVisible: Bool
    @State private var showsRestDetails = true
    @State private var activeReplacePicker: WorkoutReplaceExerciseContext?
    @State private var activeInsertPicker: WorkoutInsertExerciseContext?

    private let setRowTransition: AnyTransition = .asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
        removal: .opacity.combined(with: .scale(scale: 0.94, anchor: .top))
    )

    init(
        session: WorkoutSession,
        exercise: WorkoutSessionExercise,
        isPaused: Bool,
        onSave: @escaping () -> Void,
        onToggleDone: @escaping (WorkoutSessionSet, Bool) -> Void
    ) {
        self.session = session
        self.exercise = exercise
        self.isPaused = isPaused
        self.onSave = onSave
        self.onToggleDone = onToggleDone
        _notesVisible = State(initialValue: !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        ExerciseCard(
            title: exercise.exerciseName,
            equipmentText: exercise.displayEquipmentText,
            tableStyle: .activeWorkout,
            showsRestTimerControl: true,
            isRestTimerActive: showsRestDetails,
            onToggleRestTimer: {
                withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                    showsRestDetails.toggle()
                }
            },
            showsMenu: true,
            addSetTitle: "Add Set",
            onAddSet: {
                withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                    addSet()
                }
            }
        ) {
            Button(notesButtonTitle, systemImage: "note.text") {
                notesVisible = true
            }

            Button("Replace", systemImage: "arrow.triangle.2.circlepath") {
                activeReplacePicker = WorkoutReplaceExerciseContext(id: exercise.persistentModelID)
            }

            Button("Reorder", systemImage: "line.3.horizontal") { }
                .disabled(true)

            Button("Create superset", systemImage: "link") { }
                .disabled(true)

            Divider()

            Button("Add exercise above", systemImage: "arrow.up") {
                activeInsertPicker = WorkoutInsertExerciseContext(
                    targetExerciseID: exercise.persistentModelID,
                    direction: .above
                )
            }

            Button("Add exercise below", systemImage: "arrow.down") {
                activeInsertPicker = WorkoutInsertExerciseContext(
                    targetExerciseID: exercise.persistentModelID,
                    direction: .below
                )
            }

            Divider()

            Button("Delete Exercise", systemImage: "trash", role: .destructive) {
                deleteExercise()
            }
        } notesContent: {
            if notesVisible || !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                TextField("Add routine notes here", text: notesBinding, axis: .vertical)
                    .font(.footnote)
                    .lineLimit(nil)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        } rowsContent: {
            LazyVStack(spacing: 8) {
                ForEach(exercise.sortedSets) { sessionSet in
                    WorkoutSessionSetRow(
                        session: session,
                        exercisePosition: exercise.position,
                        sessionSet: sessionSet,
                        isPaused: isPaused,
                        showsRestDetails: showsRestDetails,
                        onSave: onSave,
                        onToggleDone: { isCompleted in
                            onToggleDone(sessionSet, isCompleted)
                        }
                    )
                    .id(sessionSet.persistentModelID)
                    .transition(setRowTransition)
                }
            }
            .animation(.snappy(duration: 0.28, extraBounce: 0.03), value: exercise.sortedSets.count)
        }
        .sheet(item: $activeReplacePicker) { context in
            NavigationStack {
                ExercisePickerView(
                    exercises: selectableExercises,
                    initiallySelectedIDs: [],
                    selectionMode: .single,
                    actionTitle: "Replace",
                    onAddSelected: { selectedExerciseItems in
                        guard let selectedExercise = selectedExerciseItems.first else {
                            return
                        }
                        replaceExercise(for: context.id, with: selectedExercise)
                    }
                )
            }
        }
        .sheet(item: $activeInsertPicker) { context in
            NavigationStack {
                ExercisePickerView(
                    exercises: selectableExercises,
                    initiallySelectedIDs: [],
                    selectionMode: .single,
                    actionTitle: "Add",
                    onAddSelected: { selectedExerciseItems in
                        guard let selectedExercise = selectedExerciseItems.first else {
                            return
                        }
                        insertExercise(selectedExercise, around: context)
                    }
                )
            }
        }
    }

    private var notesButtonTitle: String {
        exercise.notes.isEmpty && !notesVisible ? "Add Notes" : "Edit Notes"
    }

    private var selectableExercises: [ExercisePickerItem] {
        availableExercises.map(\.pickerItem)
    }

    private func sourceExercise(for exerciseID: PersistentIdentifier) -> Exercise? {
        availableExercises.first { $0.persistentModelID == exerciseID }
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { exercise.notes },
            set: { newValue in
                exercise.notes = newValue
                onSave()
            }
        )
    }

    private func addSet() {
        let nextPosition = (exercise.sortedSets.last?.position ?? 0) + 1
        let lastSet = exercise.sortedSets.last
        let newSet = WorkoutSessionSet(
            position: nextPosition,
            prescribedWeight: lastSet?.prescribedWeight,
            targetReps: lastSet?.targetReps,
            targetRepMin: lastSet?.targetRepMin,
            targetRepMax: lastSet?.targetRepMax,
            restSeconds: lastSet?.effectiveRestSeconds ?? exercise.defaultRestSeconds,
            typeRawValue: TemplateSetType.normal.rawValue,
            sessionExercise: exercise
        )

        exercise.sets.append(newSet)
        onSave()
    }

    private func deleteExercise() {
        guard let session = exercise.session else {
            return
        }

        session.clearActiveRest()
        session.exercises.removeAll { $0.persistentModelID == exercise.persistentModelID }
        modelContext.delete(exercise)
        normalizeExercisePositions(in: session)
        onSave()
    }

    private func replaceExercise(for targetID: PersistentIdentifier, with selectedExercise: ExercisePickerItem) {
        guard exercise.persistentModelID == targetID else {
            return
        }

        exercise.exerciseName = selectedExercise.name
        exercise.sourceExercise = sourceExercise(for: selectedExercise.id)
        onSave()
        activeReplacePicker = nil
    }

    private func insertExercise(_ selectedExercise: ExercisePickerItem, around context: WorkoutInsertExerciseContext) {
        guard exercise.persistentModelID == context.targetExerciseID,
              let session = exercise.session
        else {
            activeInsertPicker = nil
            return
        }

        let sortedExercises = session.sortedExercises
        guard let targetIndex = sortedExercises.firstIndex(where: { $0.persistentModelID == context.targetExerciseID }) else {
            activeInsertPicker = nil
            return
        }

        let insertionIndex = switch context.direction {
        case .above:
            targetIndex
        case .below:
            targetIndex + 1
        }

        let insertionPosition = insertionIndex + 1
        for sessionExercise in sortedExercises where sessionExercise.position >= insertionPosition {
            sessionExercise.position += 1
        }

        let sourceExercise = sourceExercise(for: selectedExercise.id)
        let insertedExercise = WorkoutSessionExercise(
            position: insertionPosition,
            exerciseName: selectedExercise.name,
            notes: "",
            defaultRestSeconds: exercise.defaultRestSeconds,
            session: session,
            sourceExercise: sourceExercise
        )

        insertedExercise.sets = [
            WorkoutSessionSet(
                position: 1,
                restSeconds: exercise.defaultRestSeconds,
                typeRawValue: TemplateSetType.normal.rawValue,
                sessionExercise: insertedExercise
            )
        ]

        session.exercises.append(insertedExercise)
        session.clearActiveRest()
        normalizeExercisePositions(in: session)
        onSave()
        activeInsertPicker = nil
    }

    private func normalizeExercisePositions(in session: WorkoutSession) {
        for (index, sessionExercise) in session.sortedExercises.enumerated() {
            sessionExercise.position = index + 1
        }
    }
}

private struct WorkoutReplaceExerciseContext: Identifiable {
    let id: PersistentIdentifier
}

private struct WorkoutInsertExerciseContext: Identifiable {
    let targetExerciseID: PersistentIdentifier
    let direction: WorkoutInsertDirection

    var id: String {
        "\(targetExerciseID)-\(direction.rawValue)"
    }
}

private enum WorkoutInsertDirection: String {
    case above
    case below
}
