import SwiftData
import SwiftUI

enum ExercisePickerSelectionMode {
    case multiple
    case single
}

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let onAddSelected: ([ExercisePickerItem]) -> Void
    let selectionMode: ExercisePickerSelectionMode
    let allowsCustomExerciseCreation: Bool
    let actionTitle: String?

    @State private var exerciseItems: [ExercisePickerItem]
    @State private var searchText = ""
    @State private var selectedBodyPart: ExerciseBodyPart?
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var selectedMode: ExerciseMode?
    @State private var selectedExerciseIDs: Set<PersistentIdentifier>
    @State private var activeSheet: ExercisePickerSheet?
    @FocusState private var isSearchFieldFocused: Bool

    init(
        exercises: [ExercisePickerItem],
        initiallySelectedIDs: Set<PersistentIdentifier>,
        selectionMode: ExercisePickerSelectionMode = .multiple,
        allowsCustomExerciseCreation: Bool = false,
        actionTitle: String? = nil,
        onAddSelected: @escaping ([ExercisePickerItem]) -> Void
    ) {
        self.onAddSelected = onAddSelected
        self.selectionMode = selectionMode
        self.allowsCustomExerciseCreation = allowsCustomExerciseCreation
        self.actionTitle = actionTitle
        _exerciseItems = State(initialValue: Self.orderedExerciseItems(exercises))

        if selectionMode == .single {
            if let first = initiallySelectedIDs.first {
                _selectedExerciseIDs = State(initialValue: [first])
            } else {
                _selectedExerciseIDs = State(initialValue: [])
            }
        } else {
            _selectedExerciseIDs = State(initialValue: initiallySelectedIDs)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            filterBar
            if allowsCustomExerciseCreation {
                customExerciseButton
            }

            List {
                if allowsCustomExerciseCreation, !filteredCustomExercises.isEmpty {
                    Section("Custom Exercises") {
                        ForEach(filteredCustomExercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }

                Section {
                    ForEach(filteredCatalogExercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }
            .overlay {
                if exerciseItems.isEmpty {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "dumbbell",
                        description: Text("Add exercises to your library first.")
                    )
                } else if filteredCatalogExercises.isEmpty && filteredCustomExercises.isEmpty {
                    ContentUnavailableView.search
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                isSearchFieldFocused = false
            }
        )
        .searchable(text: $searchText, prompt: "Search exercises")
        .searchFocused($isSearchFieldFocused)
        .navigationTitle("Select Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(toolbarActionTitle) {
                    addSelectedAndDismiss()
                }
                .disabled(selectedExerciseIDs.isEmpty)
            }

            ToolbarItemGroup(placement: .keyboard) {
                if isSearchFieldFocused {
                    Spacer()
                    Button {
                        isSearchFieldFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                    .accessibilityLabel("Hide keyboard")
                }
            }
        }
        .animation(.snappy(duration: 0.25), value: exerciseItems.isEmpty)
        .animation(.snappy(duration: 0.25), value: filteredCustomExercises.count)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .createCustomExercise:
                NavigationStack {
                    CreateCustomExerciseView { exercise in
                        handleCustomExerciseSave(exercise)
                    }
                }
            case .filter(let picker):
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
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(
                    title: selectedBodyPart?.rawValue ?? "Body Part",
                    isActive: selectedBodyPart != nil
                ) {
                    isSearchFieldFocused = false
                    activeSheet = .filter(.bodyPart)
                }

                FilterChip(
                    title: selectedEquipment?.rawValue ?? "Equipment",
                    isActive: selectedEquipment != nil
                ) {
                    isSearchFieldFocused = false
                    activeSheet = .filter(.equipment)
                }

                FilterChip(
                    title: selectedMode?.rawValue ?? "Mode",
                    isActive: selectedMode != nil
                ) {
                    isSearchFieldFocused = false
                    activeSheet = .filter(.mode)
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

    private var customExerciseButton: some View {
        Button {
            isSearchFieldFocused = false
            activeSheet = .createCustomExercise
        } label: {
            Label("Add custom exercise", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Color.accentColor)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var filteredCatalogExercises: [ExercisePickerItem] {
        filteredExercises(matching: .catalog)
    }

    private var filteredCustomExercises: [ExercisePickerItem] {
        filteredExercises(matching: .custom)
    }

    private func filteredExercises(matching source: ExercisePickerSource) -> [ExercisePickerItem] {
        let filteredByBodyPart = exerciseItems.filter { exercise in
            guard let selectedBodyPart else { return true }
            return exercise.allBodyParts.contains(selectedBodyPart)
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
        let filteredByQuery = if query.isEmpty {
            filteredByMode
        } else {
            filteredByMode.filter { exercise in
                exercise.name.localizedStandardContains(query)
            }
        }

        return filteredByQuery.filter { exercise in
            exercise.source == source
        }
    }

    private var selectedItemsOrderedByCatalog: [ExercisePickerItem] {
        let selected = exerciseItems.filter { selectedExerciseIDs.contains($0.id) }
        if selectionMode == .single {
            return Array(selected.prefix(1))
        }

        return selected
    }

    private func toggleSelection(for exerciseID: PersistentIdentifier) {
        if selectionMode == .single {
            if selectedExerciseIDs.contains(exerciseID) {
                selectedExerciseIDs.remove(exerciseID)
            } else {
                selectedExerciseIDs = [exerciseID]
            }
        } else {
            if selectedExerciseIDs.contains(exerciseID) {
                selectedExerciseIDs.remove(exerciseID)
            } else {
                selectedExerciseIDs.insert(exerciseID)
            }
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

    private var toolbarActionTitle: String {
        if let actionTitle {
            return actionTitle
        }

        return selectionMode == .single ? "Replace" : "Add"
    }

    private func exerciseRow(_ exercise: ExercisePickerItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .foregroundStyle(.primary)

                Text(exercise.equipment.rawValue)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            selectionButton(for: exercise)
        }
    }

    private func selectionButton(for exercise: ExercisePickerItem) -> some View {
        let isSelected = selectedExerciseIDs.contains(exercise.id)
        let unselectedIconName = selectionMode == .single ? "arrow.triangle.2.circlepath" : "plus"

        return Button {
            toggleSelection(for: exercise.id)
        } label: {
            Image(systemName: isSelected ? "checkmark" : unselectedIconName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                .frame(width: 32, height: 32)
                .background(
                    isSelected ? Color.accentColor : Color.clear,
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? Color.accentColor : Color(.separator),
                            lineWidth: 1
                        )
                }
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "Deselect \(exercise.name)" : "Select \(exercise.name)")
    }

    private func addSelectedAndDismiss() {
        onAddSelected(selectedItemsOrderedByCatalog)
        dismiss()
    }

    private func handleCustomExerciseSave(_ exercise: Exercise) {
        let pickerItem = exercise.pickerItem
        guard !exerciseItems.contains(where: { $0.id == pickerItem.id }) else {
            return
        }

        exerciseItems = Self.orderedExerciseItems(exerciseItems + [pickerItem])
    }

    private static func orderedExerciseItems(_ items: [ExercisePickerItem]) -> [ExercisePickerItem] {
        items.sorted { left, right in
            let sourceOrder: (ExercisePickerSource) -> Int = { source in
                source == .custom ? 0 : 1
            }

            if sourceOrder(left.source) != sourceOrder(right.source) {
                return sourceOrder(left.source) < sourceOrder(right.source)
            }

            let nameComparison = left.name.localizedStandardCompare(right.name)
            if nameComparison != .orderedSame {
                return nameComparison == .orderedAscending
            }

            if left.equipment.rawValue != right.equipment.rawValue {
                return left.equipment.rawValue.localizedStandardCompare(right.equipment.rawValue) == .orderedAscending
            }

            // PersistentIdentifier doesn't have a stable string representation,
            // but items reaching this point are effectively equivalent for display purposes
            return false
        }
    }
}

private enum ExercisePickerSheet: Identifiable {
    case filter(ExerciseFilterPicker)
    case createCustomExercise

    var id: String {
        switch self {
        case .filter(let picker):
            return "filter-\(picker.id)"
        case .createCustomExercise:
            return "create-custom-exercise"
        }
    }
}

#Preview("Standard Flow") {
    TemplateExercisePickerPreviewHost()
        .modelContainer(TemplateExercisePickerPreview.container)
}

private enum TemplateExercisePickerPreview {
    static let container: ModelContainer = {
        let container = IronRecordModelContainer.makeContainer(inMemory: true)
        try! SeedData.seedIfNeeded(in: container.mainContext)
        return container
    }()

    static var items: [ExercisePickerItem] {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        let exercises = try! container.mainContext.fetch(descriptor)

        return exercises.map(\.pickerItem)
    }
}

private struct TemplateExercisePickerPreviewHost: View {
    var body: some View {
        NavigationStack {
            ExercisePickerView(
                exercises: TemplateExercisePickerPreview.items,
                initiallySelectedIDs: Set(TemplateExercisePickerPreview.items.prefix(1).map(\.id)),
                allowsCustomExerciseCreation: true,
                onAddSelected: { _ in }
            )
        }
    }
}
