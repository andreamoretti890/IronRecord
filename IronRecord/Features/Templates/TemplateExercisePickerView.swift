import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let exercises: [ExercisePickerItem]
    let onAddSelected: ([ExercisePickerItem]) -> Void

    @State private var searchText = ""
    @State private var selectedBodyPart: ExerciseBodyPart?
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var selectedMode: ExerciseMode?
    @State private var selectedExerciseIDs: Set<String>
    @State private var activeFilterPicker: ExerciseFilterPicker?
    @FocusState private var isSearchFieldFocused: Bool

    init(
        exercises: [ExercisePickerItem],
        initiallySelectedIDs: Set<String>,
        onAddSelected: @escaping ([ExercisePickerItem]) -> Void
    ) {
        self.exercises = exercises
        self.onAddSelected = onAddSelected
        _selectedExerciseIDs = State(initialValue: initiallySelectedIDs)
    }

    var body: some View {
        VStack(spacing: 10) {
            filterBar

            List(filteredExercises) { exercise in
                Button {
                    toggleSelection(for: exercise.id)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(exercise.name)
                                .foregroundStyle(.primary)
                            Text(exercise.bodyPart.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedExerciseIDs.contains(exercise.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .overlay {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "dumbbell",
                        description: Text("Add exercises to your library first.")
                    )
                } else if filteredExercises.isEmpty {
                    ContentUnavailableView.search
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
        .searchFocused($isSearchFieldFocused)
        .navigationTitle("Select Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            isSearchFieldFocused = true
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Create") {
                    // Placeholder for custom exercise creation flow.
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !exercises.isEmpty && !selectedExerciseIDs.isEmpty {
                selectionDock
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: selectedExerciseIDs.count)
        .animation(.snappy(duration: 0.25), value: exercises.isEmpty)
        .sheet(item: $activeFilterPicker) { picker in
            NavigationStack {
                FilterSelectionSheet(
                    title: picker.title,
                    allLabel: picker.allLabel,
                    options: options(for: picker),
                    selectedOptionID: selectedOptionID(for: picker),
                    onSelect: { optionID in
                        applyFilterSelection(optionID, for: picker)
                    }
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(
                    title: selectedBodyPart?.rawValue ?? "Body Part",
                    isActive: selectedBodyPart != nil
                ) {
                    isSearchFieldFocused = false
                    activeFilterPicker = .bodyPart
                }

                FilterChip(
                    title: selectedEquipment?.rawValue ?? "Equipment",
                    isActive: selectedEquipment != nil
                ) {
                    isSearchFieldFocused = false
                    activeFilterPicker = .equipment
                }

                FilterChip(
                    title: selectedMode?.rawValue ?? "Mode",
                    isActive: selectedMode != nil
                ) {
                    isSearchFieldFocused = false
                    activeFilterPicker = .mode
                }

                if hasActiveFilters {
                    FilterChip(
                        title: "Reset",
                        isActive: false,
                        showsChevron: false,
                        tintText: true
                    ) {
                        selectedBodyPart = nil
                        selectedEquipment = nil
                        selectedMode = nil
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var filteredExercises: [ExercisePickerItem] {
        let filteredByBodyPart = exercises.filter { exercise in
            guard let selectedBodyPart else { return true }
            return exercise.bodyPart == selectedBodyPart
        }

        let filteredByEquipment = filteredByBodyPart.filter { exercise in
            guard let selectedEquipment else { return true }
            return exercise.equipment == selectedEquipment
        }

        let filteredByMode = filteredByEquipment.filter { exercise in
            guard let selectedMode else { return true }
            return exercise.mode == selectedMode
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return filteredByMode }
        return filteredByMode.filter { exercise in
            exercise.name.localizedStandardContains(query)
        }
    }

    private var selectedItemsOrderedByCatalog: [ExercisePickerItem] {
        exercises
            .filter { selectedExerciseIDs.contains($0.id) }
    }

    private func toggleSelection(for exerciseID: String) {
        if selectedExerciseIDs.contains(exerciseID) {
            selectedExerciseIDs.remove(exerciseID)
        } else {
            selectedExerciseIDs.insert(exerciseID)
        }
    }

    private func options(for picker: ExerciseFilterPicker) -> [FilterOption] {
        switch picker {
        case .bodyPart:
            return ExerciseBodyPart.filterOrder.map { option in
                FilterOption(id: option.id, title: option.rawValue)
            }
        case .equipment:
            return ExerciseEquipment.filterOrder.map { option in
                FilterOption(id: option.id, title: option.rawValue)
            }
        case .mode:
            return ExerciseMode.filterOrder.map { option in
                FilterOption(id: option.id, title: option.rawValue)
            }
        }
    }

    private func selectedOptionID(for picker: ExerciseFilterPicker) -> String? {
        switch picker {
        case .bodyPart: return selectedBodyPart?.id
        case .equipment: return selectedEquipment?.id
        case .mode: return selectedMode?.id
        }
    }

    private func applyFilterSelection(_ optionID: String?, for picker: ExerciseFilterPicker) {
        switch picker {
        case .bodyPart:
            selectedBodyPart = optionID.flatMap(ExerciseBodyPart.init(rawValue:))
        case .equipment:
            selectedEquipment = optionID.flatMap(ExerciseEquipment.init(rawValue:))
        case .mode:
            selectedMode = optionID.flatMap(ExerciseMode.init(rawValue:))
        }
    }

    private var hasActiveFilters: Bool {
        selectedBodyPart != nil || selectedEquipment != nil || selectedMode != nil
    }

    private var selectionDock: some View {
        Button {
            addSelectedAndDismiss()
        } label: {
            Text(addButtonTitle)
                .frame(maxWidth: .infinity)
                .contentTransition(.numericText())
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(selectedExerciseIDs.isEmpty)
        .accessibilityLabel("Add selected exercises")
        .accessibilityValue("\(selectedExerciseIDs.count) selected")
        .buttonBorderShape(.capsule)
    }

    private var addButtonTitle: String {
        let count = selectedExerciseIDs.count
        switch count {
        case 0:
            return "Add exercises"
        case 1:
            return "Add 1 exercise"
        default:
            return "Add \(count) exercises"
        }
    }

    private func addSelectedAndDismiss() {
        onAddSelected(selectedItemsOrderedByCatalog)
        dismiss()
    }
}
