//
//  TemplateExercisePickerView.swift
//  IronRecord
//
//  Created by Codex on 17/02/26.
//

import SwiftUI

struct TemplateExercisePickerView: View {
    let exercises: [Exercise]
    let onCancel: () -> Void
    let onAddSelected: ([Exercise]) -> Void

    @State private var searchText = ""
    @State private var selectedExerciseNames: Set<String> = []
    @State private var selectionOrder: [String] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.exercises, id: \.name) { exercise in
                            Button {
                                toggleSelection(for: exercise)
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .font(.body)
                                        Text(exercise.equipment)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedExerciseNames.contains(exercise.name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.tint)
                                            .accessibilityHidden(true)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.tertiary)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(exercise.name)
                            .accessibilityHint(selectionHint(for: exercise))
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Selected (\(selectedExercises.count))") {
                        onAddSelected(selectedExercises)
                    }
                    .disabled(selectedExercises.isEmpty)
                    .accessibilityHint("Adds selected exercises to this template")
                }
            }
        }
    }

    private var filteredExercises: [Exercise] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return exercises
        }

        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(trimmedSearch) ||
            exercise.category.localizedCaseInsensitiveContains(trimmedSearch) ||
            exercise.equipment.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private var groupedExercises: [ExerciseCategoryGroup] {
        let grouped = Dictionary(grouping: filteredExercises, by: \.category)

        return grouped.keys.sorted().map { category in
            ExerciseCategoryGroup(
                category: category,
                exercises: grouped[category, default: []].sorted { left, right in
                    left.name < right.name
                }
            )
        }
    }

    private var selectedExercises: [Exercise] {
        let exerciseByName = Dictionary(uniqueKeysWithValues: exercises.map { ($0.name, $0) })

        return selectionOrder.compactMap { exerciseByName[$0] }
    }

    private func toggleSelection(for exercise: Exercise) {
        if selectedExerciseNames.contains(exercise.name) {
            selectedExerciseNames.remove(exercise.name)
            selectionOrder.removeAll { $0 == exercise.name }
        } else {
            selectedExerciseNames.insert(exercise.name)
            selectionOrder.append(exercise.name)
        }
    }

    private func selectionHint(for exercise: Exercise) -> String {
        if selectedExerciseNames.contains(exercise.name) {
            return "Double tap to deselect"
        } else {
            return "Double tap to select"
        }
    }
}

private struct ExerciseCategoryGroup {
    let category: String
    let exercises: [Exercise]
}
