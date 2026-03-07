//
//  TemplatesView.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]

    @State private var isEditorPresented = false
    @State private var editingTemplate: WorkoutTemplate?
    @State private var editorDraft = TemplateDraft(name: "", notes: "", exercises: [])
    @State private var templatePendingDeletion: WorkoutTemplate?
    @State private var errorMessage: String?

    var body: some View {
        List {
            if templates.isEmpty {
                ContentUnavailableView {
                    Label("No Templates", systemImage: "list.bullet.rectangle.portrait")
                } description: {
                    Text("Create your first template to start logging workouts.")
                } actions: {
                    Button("New Template", systemImage: "plus") {
                        presentCreateTemplate()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(exercises.isEmpty)
                }
            } else {
                ForEach(templates) { template in
                    NavigationLink {
                        TemplateDetailView(
                            template: template,
                            onEdit: {
                                presentEditTemplate(template)
                            },
                            onDelete: {
                                confirmDelete(template)
                            }
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(template.name)
                                .font(.headline)

                            Text("\(template.exercises.count) exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            confirmDelete(template)
                        }

                        Button("Edit", systemImage: "pencil") {
                            presentEditTemplate(template)
                        }
                    }
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New", systemImage: "plus") {
                    presentCreateTemplate()
                }
                .disabled(exercises.isEmpty)
                .accessibilityHint("Creates a new workout template")
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            NavigationStack {
                TemplateEditorView(
                    draft: $editorDraft,
                    availableExercises: exercises,
                    mode: editingTemplate == nil ? .create : .edit,
                    onCancel: {
                        dismissEditor()
                    },
                    onSave: {
                        saveTemplateFromEditor()
                    }
                )
            }
        }
        .confirmationDialog(
            "Delete Template",
            isPresented: isShowingDeleteConfirmation,
            presenting: templatePendingDeletion
        ) { template in
            Button("Delete Template", role: .destructive) {
                deleteTemplate(template)
            }

            Button("Cancel", role: .cancel) { }
        } message: { template in
            if template.routineDays.isEmpty {
                Text("This action cannot be undone.")
            } else {
                Text("This template is used in \(template.routineDays.count) routine day(s). Those days will become unassigned.")
            }
        }
        .alert(
            "Template Error",
            isPresented: isShowingError,
            actions: {
                Button("OK", role: .cancel) { }
            },
            message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        )
    }

    private var isShowingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { templatePendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    templatePendingDeletion = nil
                }
            }
        )
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func presentCreateTemplate() {
        editingTemplate = nil
        editorDraft = TemplateDraft.new(defaultExerciseName: nil)
        isEditorPresented = true
    }

    private func presentEditTemplate(_ template: WorkoutTemplate) {
        editingTemplate = template
        editorDraft = TemplateDraft(template: template)
        isEditorPresented = true
    }

    private func dismissEditor() {
        isEditorPresented = false
    }

    private func confirmDelete(_ template: WorkoutTemplate) {
        templatePendingDeletion = template
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Could not delete template. Try again."
        }
    }

    private func saveTemplateFromEditor() {
        let trimmedName = editorDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = editorDraft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let validExerciseNames = Set(exercises.map(\.name))

        guard !trimmedName.isEmpty else {
            errorMessage = "Template name is required."
            return
        }

        guard !editorDraft.exercises.isEmpty else {
            errorMessage = "Add at least one exercise."
            return
        }

        guard editorDraft.exercises.allSatisfy({ validExerciseNames.contains($0.exerciseName) }) else {
            errorMessage = "One or more selected exercises are no longer available."
            return
        }

        guard !isDuplicateTemplateName(trimmedName, excluding: editingTemplate) else {
            errorMessage = "A template with this name already exists."
            return
        }

        let exerciseByName = Dictionary(uniqueKeysWithValues: exercises.map { ($0.name, $0) })

        do {
            if let editingTemplate {
                editingTemplate.name = trimmedName
                editingTemplate.notes = trimmedNotes
                replaceTemplateExercises(
                    for: editingTemplate,
                    using: editorDraft.exercises,
                    exerciseByName: exerciseByName
                )
            } else {
                let newTemplate = WorkoutTemplate(name: trimmedName, notes: trimmedNotes)
                modelContext.insert(newTemplate)
                replaceTemplateExercises(
                    for: newTemplate,
                    using: editorDraft.exercises,
                    exerciseByName: exerciseByName
                )
            }

            try modelContext.save()
            dismissEditor()
        } catch {
            errorMessage = "Could not save template. Try again."
        }
    }

    private func replaceTemplateExercises(
        for template: WorkoutTemplate,
        using exerciseDrafts: [TemplateExerciseDraft],
        exerciseByName: [String: Exercise]
    ) {
        let existingEntries = template.exercises

        for entry in existingEntries {
            modelContext.delete(entry)
        }

        template.exercises.removeAll()

        for (index, draftExercise) in exerciseDrafts.enumerated() {
            guard let exercise = exerciseByName[draftExercise.exerciseName] else {
                continue
            }

            let entry = TemplateExercise(
                position: index + 1,
                targetSets: draftExercise.targetSets,
                targetReps: draftExercise.targetReps,
                restSeconds: draftExercise.restSeconds,
                notes: draftExercise.notes,
                exercise: exercise
            )

            template.exercises.append(entry)
            modelContext.insert(entry)
        }
    }

    private func isDuplicateTemplateName(_ name: String, excluding template: WorkoutTemplate?) -> Bool {
        templates.contains { existingTemplate in
            if let template, existingTemplate.persistentModelID == template.persistentModelID {
                return false
            }

            return existingTemplate.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }
    }
}

private struct TemplateDetailView: View {
    let template: WorkoutTemplate
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        List {
            if !template.notes.isEmpty {
                Section("Notes") {
                    Text(template.notes)
                        .font(.body)
                }
            }

            Section("Exercise Prescription") {
                ForEach(sortedExercises) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.exercise?.name ?? "Unknown exercise")
                            .font(.headline)
                        Text("\(entry.targetSets) x \(repTargetText(for: entry)) • Rest \(entry.restSeconds)s")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if !entry.notes.isEmpty {
                            Text(entry.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Template exercise target")
                }
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Actions", systemImage: "ellipsis.circle") {
                    Button("Edit Template", systemImage: "pencil") {
                        onEdit()
                    }
                    Button("Delete Template", systemImage: "trash", role: .destructive) {
                        onDelete()
                    }
                }
                .accessibilityLabel("Template actions")
            }
        }
    }

    private var sortedExercises: [TemplateExercise] {
        template.exercises.sorted { left, right in
            left.position < right.position
        }
    }

    private func repTargetText(for entry: TemplateExercise) -> String {
        let trimmedTarget = entry.targetReps.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTarget.isEmpty ? "No rep target" : trimmedTarget
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
    }
    .modelContainer(
        for: [
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            Routine.self,
            RoutineDay.self,
            WorkoutSession.self,
            SetEntry.self
        ],
        inMemory: true
    )
}
