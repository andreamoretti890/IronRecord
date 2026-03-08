import SwiftData
import SwiftUI

struct AddTemplateView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var availableExercises: [Exercise]

    @State private var title = ""
    @State private var exercises: [ExercisePickerItem] = []

    var onSave: (TemplateRowItem) -> Void

    var body: some View {
        Form {
            Section("Title") {
                TextField("Template title", text: $title)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }

            Section("Exercises") {
                if exercises.isEmpty {
                    Text("No exercises added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(exercises) { exercise in
                        Text(exercise.name)
                    }
                    .onDelete(perform: deleteExercises)
                }

                NavigationLink {
                    ExercisePickerView(
                        exercises: selectableExercises,
                        initiallySelectedIDs: Set(exercises.map(\.id)),
                        onAddSelected: { selectedExerciseItems in
                            addExercises(selectedExerciseItems)
                        }
                    )
                } label: {
                    Label("Add Exercises", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Add Template")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveRoutine()
                }
                .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && !exercises.isEmpty
    }

    private var selectableExercises: [ExercisePickerItem] {
        let modelExercises = availableExercises.map { exercise in
            ExercisePickerItem(
                id: String(describing: exercise.persistentModelID),
                name: exercise.name,
                bodyPart: ExerciseBodyPart.fromStoredValue(exercise.bodyPart),
                equipment: ExerciseEquipment.infer(
                    equipment: exercise.equipment,
                    exerciseName: exercise.name
                ),
                mode: ExerciseMode.infer(
                    equipment: exercise.equipment,
                    exerciseName: exercise.name
                )
            )
        }

        guard !modelExercises.isEmpty else {
            let fallbackNames = Set(TemplateRowItem.mock.flatMap(\.exercises)).sorted()
            return fallbackNames.enumerated().map { index, name in
                ExercisePickerItem(
                    id: "fallback-\(index)-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))",
                    name: name,
                    bodyPart: .others,
                    equipment: ExerciseEquipment.infer(
                        equipment: "",
                        exerciseName: name
                    ),
                    mode: ExerciseMode.infer(
                        equipment: "",
                        exerciseName: name
                    )
                )
            }
        }

        return modelExercises
    }

    private func addExercises(_ selectedItems: [ExercisePickerItem]) {
        var existingIDs = Set(exercises.map(\.id))
        for item in selectedItems where existingIDs.insert(item.id).inserted {
            exercises.append(item)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    private func saveRoutine() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !exercises.isEmpty else {
            return
        }

        onSave(TemplateRowItem(title: trimmedTitle, exercises: exercises.map(\.name)))
        dismiss()
    }
}
