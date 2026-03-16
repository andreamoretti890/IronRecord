import SwiftUI

struct TemplateExerciseReorderSheet: View {
    let onSave: ([TemplateExerciseDraft]) -> Void

    @State private var exercises: [TemplateExerciseDraft]
    @State private var editMode: EditMode = .active

    init(
        exercises: [TemplateExerciseDraft],
        onSave: @escaping ([TemplateExerciseDraft]) -> Void
    ) {
        self.onSave = onSave
        _exercises = State(initialValue: exercises)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(exercises) { exercise in
                    ReorderExerciseRow(exercise: exercise)
                        .moveDisabled(exercises.count < 2)
                        .listRowInsets(.init(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 16))
                }
                .onMove(perform: moveItems)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .environment(\.editMode, $editMode)
            .safeAreaInset(edge: .bottom) {
                Button {
                    onSave(exercises)
                } label: {
                    Text("Save")
                        .foregroundStyle(Color(.label))
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.glassProminent)
                .padding(16)
            }
            .navigationTitle("Reorder Exercises")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
}


private struct ReorderExerciseRow: View {
    let exercise: TemplateExerciseDraft

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var subtitle: String {
        let setCount = exercise.sets.count
        let setSummary = setCount == 1 ? "1 set" : "\(setCount) sets"
        let equipment = exercise.equipment.trimmingCharacters(in: .whitespacesAndNewlines)

        if equipment.isEmpty {
            return setSummary
        }

        return "\(equipment) • \(setSummary)"
    }
}

#Preview("Reorder Sheet") {
    TemplateExerciseReorderSheet(
        exercises: [
            TemplateExerciseDraft(
                exerciseID: nil,
                name: "Overhead Triceps Extension",
                equipment: "Cable (Single)",
                notes: "",
                notesVisible: false,
                showsRestTimer: false,
                sets: Array(repeating: .empty, count: 3)
            ),
            TemplateExerciseDraft(
                exerciseID: nil,
                name: "Incline Bench Press",
                equipment: "Dumbbell (Double)",
                notes: "",
                notesVisible: false,
                showsRestTimer: false,
                sets: Array(repeating: .empty, count: 3)
            ),
            TemplateExerciseDraft(
                exerciseID: nil,
                name: "Close Grip Bench Press",
                equipment: "Barbell",
                notes: "",
                notesVisible: false,
                showsRestTimer: false,
                sets: Array(repeating: .empty, count: 2)
            )
        ],
        onSave: { _ in }
    )
}
