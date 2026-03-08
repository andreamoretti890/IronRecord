//
//  TemplatesView.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import SwiftData
import SwiftUI

struct TemplatesView: View {
    @State private var templates = TemplateRowItem.mock
    @State private var templatePendingDeletion: TemplateRowItem?
    @State private var isAddRoutinePresented = false

    var body: some View {
        List {
            ForEach(templates) { template in
                TemplateRowView(
                    template: template,
                    onDeleteTapped: {
                        templatePendingDeletion = template
                    }
                )
                    .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Templates")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Template", systemImage: "plus") {
                    isAddRoutinePresented = true
                }
                    .accessibilityHint("Creates a new template")
            }
        }
        .sheet(isPresented: $isAddRoutinePresented) {
            NavigationStack {
                AddTemplateView { newTemplate in
                    templates.append(newTemplate)
                }
            }
            .interactiveDismissDisabled()
        }
        .alert(
            "Delete Template",
            isPresented: isShowingDeleteAlert,
            presenting: templatePendingDeletion
        ) { template in
            Button("Delete", role: .destructive) {
                deleteTemplate(template)
            }
            Button("Cancel", role: .cancel) { }
        } message: { template in
            Text("Delete \(template.title)? This action cannot be undone.")
        }
    }

    private var isShowingDeleteAlert: Binding<Bool> {
        Binding(
            get: { templatePendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    templatePendingDeletion = nil
                }
            }
        )
    }

    private func deleteTemplate(_ template: TemplateRowItem) {
        templates.removeAll { $0.id == template.id }
        templatePendingDeletion = nil
    }
}

private struct AddTemplateView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var availableExercises: [Exercise]

    @State private var title = ""
    @State private var exercises: [String] = []

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
                    ForEach(exercises, id: \.self) { exercise in
                        Text(exercise)
                    }
                    .onDelete(perform: deleteExercises)
                }

                NavigationLink {
                    ExercisePickerView(
                        exercises: selectableExercises,
                        initiallySelected: Set(exercises),
                        onAddSelected: { selectedExerciseNames in
                            addExercises(selectedExerciseNames)
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
                name: exercise.name,
                bodyPart: ExerciseBodyPart.infer(
                    category: exercise.category,
                    exerciseName: exercise.name
                ),
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
            return fallbackNames.map { name in
                ExercisePickerItem(
                    name: name,
                    bodyPart: ExerciseBodyPart.infer(
                        category: "",
                        exerciseName: name
                    ),
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

    private func addExercises(_ names: [String]) {
        for name in names where !exercises.contains(name) {
            exercises.append(name)
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

        onSave(TemplateRowItem(title: trimmedTitle, exercises: exercises))
        dismiss()
    }
}

private struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let exercises: [ExercisePickerItem]
    let onAddSelected: ([String]) -> Void

    @State private var searchText = ""
    @State private var selectedBodyPart: ExerciseBodyPart?
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var selectedMode: ExerciseMode?
    @State private var selectedExerciseNames: Set<String>
    @State private var activeFilterPicker: ExerciseFilterPicker?
    @FocusState private var isSearchFieldFocused: Bool

    init(
        exercises: [ExercisePickerItem],
        initiallySelected: Set<String>,
        onAddSelected: @escaping ([String]) -> Void
    ) {
        self.exercises = exercises
        self.onAddSelected = onAddSelected
        _selectedExerciseNames = State(initialValue: initiallySelected)
    }

    var body: some View {
        VStack(spacing: 10) {
            filterBar

            List(filteredExercises) { exercise in
                Button {
                    toggleSelection(for: exercise.name)
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

                        if selectedExerciseNames.contains(exercise.name) {
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

            ToolbarItem(placement: .confirmationAction) {
                Button("Add (\(selectedExerciseNames.count))") {
                    onAddSelected(selectedNamesOrderedByCatalog)
                    dismiss()
                }
                .disabled(selectedExerciseNames.isEmpty)
            }
        }
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
                    Button("Reset") {
                        selectedBodyPart = nil
                        selectedEquipment = nil
                        selectedMode = nil
                    }
                    .buttonStyle(.bordered)
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

    private var selectedNamesOrderedByCatalog: [String] {
        exercises
            .map(\.name)
            .filter { selectedExerciseNames.contains($0) }
    }

    private func toggleSelection(for exerciseName: String) {
        if selectedExerciseNames.contains(exerciseName) {
            selectedExerciseNames.remove(exerciseName)
        } else {
            selectedExerciseNames.insert(exerciseName)
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
}

private struct ExercisePickerItem: Identifiable, Hashable {
    let name: String
    let bodyPart: ExerciseBodyPart
    let equipment: ExerciseEquipment
    let mode: ExerciseMode

    var id: String { name }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isActive
                    ? Color.accentColor.opacity(0.14)
                    : Color(.secondarySystemBackground),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        isActive ? Color.accentColor.opacity(0.6) : Color(.separator),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? Color.accentColor : Color.primary)
    }
}

private struct FilterOption: Identifiable {
    let id: String
    let title: String
}

private enum ExerciseFilterPicker: String, Identifiable {
    case bodyPart
    case equipment
    case mode

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bodyPart: return "Body Part"
        case .equipment: return "Equipment"
        case .mode: return "Exercise Mode"
        }
    }

    var allLabel: String {
        switch self {
        case .bodyPart: return "All Body Parts"
        case .equipment: return "All Equipment"
        case .mode: return "All Modes"
        }
    }
}

private struct FilterSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let allLabel: String
    let options: [FilterOption]
    let selectedOptionID: String?
    let onSelect: (String?) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                filterRow(
                    title: allLabel,
                    isSelected: selectedOptionID == nil,
                    action: {
                        onSelect(nil)
                        dismiss()
                    }
                )

                ForEach(options) { option in
                    filterRow(
                        title: option.title,
                        isSelected: selectedOptionID == option.id,
                        action: {
                            onSelect(option.id)
                            dismiss()
                        }
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func filterRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.12)
                    : Color(.secondarySystemBackground),
                in: .rect(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.45) : Color(.separator),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

private enum ExerciseEquipment: String, CaseIterable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case weightedBodyweight = "Weighted Bodyweight"
    case assistedBodyweight = "Assisted Bodyweight"
    case bodyweight = "Bodyweight"
    case cardio = "Cardio"
    case other = "Other"

    var id: String { rawValue }

    static var filterOrder: [ExerciseEquipment] {
        [
            .barbell,
            .dumbbell,
            .machine,
            .cable,
            .weightedBodyweight,
            .assistedBodyweight,
            .bodyweight,
            .cardio,
            .other
        ]
    }

    static func infer(equipment: String, exerciseName: String) -> ExerciseEquipment {
        let value = "\(equipment) \(exerciseName)".lowercased()

        if value.contains("cardio")
            || value.contains("bike")
            || value.contains("run")
            || value.contains("rower") {
            return .cardio
        }
        if value.contains("weighted bodyweight") { return .weightedBodyweight }
        if value.contains("assisted bodyweight") { return .assistedBodyweight }
        if value.contains("bodyweight") || value.contains("pull-up") { return .bodyweight }
        if value.contains("barbell") { return .barbell }
        if value.contains("dumbbell") { return .dumbbell }
        if value.contains("machine") || value.contains("leg press") { return .machine }
        if value.contains("cable") { return .cable }

        return .other
    }
}

private enum ExerciseMode: String, CaseIterable, Identifiable {
    case weightedReps = "Weighted Reps"
    case repsOnly = "Reps Only"
    case cardioDuration = "Cardio Duration"

    var id: String { rawValue }

    static var filterOrder: [ExerciseMode] {
        [
            .weightedReps,
            .repsOnly,
            .cardioDuration
        ]
    }

    static func infer(equipment: String, exerciseName: String) -> ExerciseMode {
        let value = "\(equipment) \(exerciseName)".lowercased()

        if value.contains("cardio")
            || value.contains("bike")
            || value.contains("run")
            || value.contains("rower") {
            return .cardioDuration
        }

        if value.contains("weighted bodyweight")
            || value.contains("barbell")
            || value.contains("dumbbell")
            || value.contains("machine")
            || value.contains("cable") {
            return .weightedReps
        }

        if value.contains("bodyweight") || value.contains("assisted bodyweight") {
            return .repsOnly
        }

        return .repsOnly
    }
}

private enum ExerciseBodyPart: String, CaseIterable, Identifiable {
    case core = "Core"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case neck = "Neck"
    case traps = "Traps"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case abductors = "Abductors"
    case adductors = "Adductors"
    case calves = "Calves"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case others = "Others"

    var id: String { rawValue }

    static var filterOrder: [ExerciseBodyPart] {
        [
            .core,
            .chest,
            .back,
            .shoulders,
            .neck,
            .traps,
            .biceps,
            .triceps,
            .forearms,
            .quadriceps,
            .hamstrings,
            .glutes,
            .abductors,
            .adductors,
            .calves,
            .fullBody,
            .cardio,
            .others
        ]
    }

    static func infer(category: String, exerciseName: String) -> ExerciseBodyPart {
        let value = "\(category) \(exerciseName)".lowercased()

        if value.contains("cardio") { return .cardio }
        if value.contains("full body") || value.contains("fullbody") { return .fullBody }
        if value.contains("abductor") { return .abductors }
        if value.contains("adductor") { return .adductors }
        if value.contains("calf") { return .calves }

        if value.contains("quadricep")
            || value.contains(" quad")
            || value.contains("squat")
            || value.contains("leg press")
            || value.contains("leg extension")
            || value.contains("lunge") {
            return .quadriceps
        }

        if value.contains("hamstring")
            || value.contains("leg curl")
            || value.contains("romanian deadlift")
            || value.contains(" rdl") {
            return .hamstrings
        }

        if value.contains("glute") || value.contains("hip thrust") { return .glutes }
        if value.contains("tricep") { return .triceps }
        if value.contains("hammer curl")
            || value.contains("forearm")
            || value.contains("wrist")
            || value.contains("grip") {
            return .forearms
        }

        if value.contains("bicep") { return .biceps }
        if value.contains("neck") { return .neck }
        if value.contains("trap")
            || value.contains("upper back")
            || value.contains("face pull") {
            return .traps
        }

        if value.contains("shoulder")
            || value.contains("deltoid")
            || value.contains("lateral raise")
            || value.contains("overhead press") {
            return .shoulders
        }

        if value.contains("chest")
            || value.contains("bench press")
            || value.contains("incline press")
            || value.contains("pec") {
            return .chest
        }

        if value.contains("core")
            || value.contains("abs")
            || value.contains("abdom")
            || value.contains("oblique")
            || value.contains("plank") {
            return .core
        }

        if value.contains("back")
            || value.contains("row")
            || value.contains("lat pulldown")
            || value.contains("pull-up")
            || value.contains("deadlift") {
            return .back
        }

        return .others
    }
}

private struct TemplateRowView: View {
    let template: TemplateRowItem
    let onDeleteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(template.title)
                    .font(.headline)

                Spacer(minLength: 8)

                Menu {
                    Button("Edit", systemImage: "pencil") { }
                    Button("Duplicate", systemImage: "square.on.square") { }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onDeleteTapped()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Template actions")
                }
                .buttonStyle(.plain)
            }

            Text(template.exercisePreview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)

            Button("Start Template") { }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Starts \(template.title)")
        }
        .padding(14)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 14))
    }
}

private struct TemplateRowItem: Identifiable {
    let id = UUID()
    let title: String
    let exercises: [String]

    var exercisePreview: String {
        exercises.joined(separator: ", ")
    }

    static let mock: [TemplateRowItem] = [
        TemplateRowItem(
            title: "Push Day A",
            exercises: ["Barbell Bench Press", "Incline Dumbbell Press", "Seated Shoulder Press", "Cable Lateral Raise"]
        ),
        TemplateRowItem(
            title: "Pull Day A",
            exercises: ["Pull-Up", "Barbell Row", "Seated Cable Row", "Face Pull"]
        ),
        TemplateRowItem(
            title: "Legs Day A",
            exercises: ["Back Squat", "Romanian Deadlift", "Leg Press", "Standing Calf Raise"]
        )
    ]
}

#Preview {
    NavigationStack {
        TemplatesView()
    }
}
