//
//  TemplateEditorView.swift
//  IronRecord
//
//  Created by Codex on 17/02/26.
//

import SwiftUI

struct TemplateEditorView: View {
    enum Mode {
        case create
        case edit

        var title: String {
            switch self {
            case .create:
                "New Template"
            case .edit:
                "Edit Template"
            }
        }

        var saveButtonTitle: String {
            switch self {
            case .create:
                "Create"
            case .edit:
                "Save"
            }
        }
    }

    @Binding var draft: TemplateDraft

    let availableExercises: [Exercise]
    let mode: Mode
    let onCancel: () -> Void
    let onSave: () -> Void

    @State private var editMode: EditMode = .inactive
    @State private var isExercisePickerPresented = false

    var body: some View {
        Form {
            detailsSection
            exercisesSection
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $isExercisePickerPresented) {
            TemplateExercisePickerView(
                exercises: availableExercises,
                onCancel: {
                    isExercisePickerPresented = false
                },
                onAddSelected: { selectedExercises in
                    addExercises(selectedExercises)
                    isExercisePickerPresented = false
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(mode.saveButtonTitle) {
                    onSave()
                }
                .disabled(!canSave)
            }

            if !draft.exercises.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Template Name", text: $draft.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .accessibilityLabel("Template name")

            TextField("Notes (optional)", text: $draft.notes, axis: .vertical)
                .lineLimit(2 ... 4)
                .accessibilityLabel("Template notes")
        }
    }

    private var exercisesSection: some View {
        Section {
            if draft.exercises.isEmpty {
                Text("Add at least one exercise.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach($draft.exercises) { $exerciseDraft in
                    NavigationLink {
                        TemplateExerciseEditorView(
                            exerciseDraft: $exerciseDraft,
                            availableExerciseNames: availableExerciseNames
                        )
                    } label: {
                        TemplateExerciseSummaryRow(exerciseDraft: exerciseDraft)
                    }
                    .accessibilityHint("Opens exercise details")
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)
            }

            Button("Add Exercise", systemImage: "plus") {
                isExercisePickerPresented = true
            }
            .disabled(availableExerciseNames.isEmpty)
            .accessibilityHint("Adds a new exercise line to this template")
        } header: {
            Text("Exercise Prescription")
        } footer: {
            if availableExerciseNames.isEmpty {
                Text("No exercises available. Starter data should add these automatically.")
            } else {
                Text("Reorder exercises with Edit.")
            }
        }
    }

    private var availableExerciseNames: [String] {
        availableExercises.map(\.name)
    }

    private var canSave: Bool {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let validExerciseNames = Set(availableExerciseNames)

        guard !trimmedName.isEmpty else {
            return false
        }

        guard !draft.exercises.isEmpty else {
            return false
        }

        return draft.exercises.allSatisfy { draftExercise in
            validExerciseNames.contains(draftExercise.exerciseName)
        }
    }

    private func addExercises(_ selectedExercises: [Exercise]) {
        guard !selectedExercises.isEmpty else {
            return
        }

        for exercise in selectedExercises {
            draft.exercises.append(
                TemplateExerciseDraft(
                    exerciseName: exercise.name,
                    targetSets: 1,
                    targetReps: "",
                    restSeconds: 90,
                    notes: ""
                )
            )
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        draft.exercises.remove(atOffsets: offsets)
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        draft.exercises.move(fromOffsets: source, toOffset: destination)
    }
}

private struct TemplateExerciseSummaryRow: View {
    let exerciseDraft: TemplateExerciseDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exerciseDraft.exerciseName)
                .font(.headline)
            Text("\(exerciseDraft.targetSets) x \(repTargetText(for: exerciseDraft)) • Rest \(exerciseDraft.restSeconds)s")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exerciseDraft.exerciseName), \(exerciseDraft.targetSets) sets, \(repTargetText(for: exerciseDraft)) reps, \(exerciseDraft.restSeconds) seconds rest")
    }

    private func repTargetText(for exerciseDraft: TemplateExerciseDraft) -> String {
        let trimmedTarget = exerciseDraft.targetReps.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTarget.isEmpty ? "No rep target" : trimmedTarget
    }
}

private struct TemplateExerciseEditorView: View {
    @Binding var exerciseDraft: TemplateExerciseDraft

    let availableExerciseNames: [String]

    var body: some View {
        Form {
            Section("Exercise") {
                Picker("Movement", selection: $exerciseDraft.exerciseName) {
                    ForEach(availableExerciseNames, id: \.self) { exerciseName in
                        Text(exerciseName).tag(exerciseName)
                    }
                }
                .accessibilityHint("Selects the movement for this template entry")
            }

            Section("Targets") {
                Stepper(value: $exerciseDraft.targetSets, in: 1 ... 10) {
                    LabeledContent("Sets", value: "\(exerciseDraft.targetSets)")
                }

                TextField("Reps (e.g. 8-12)", text: $exerciseDraft.targetReps)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Rep target")

                Stepper(value: $exerciseDraft.restSeconds, in: 15 ... 300, step: 15) {
                    LabeledContent("Rest", value: "\(exerciseDraft.restSeconds)s")
                }
            }

            Section("Notes") {
                TextField("Optional notes", text: $exerciseDraft.notes, axis: .vertical)
                    .lineLimit(2 ... 4)
                    .accessibilityLabel("Exercise notes")
            }
        }
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }
}
