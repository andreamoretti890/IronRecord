import SwiftData
import SwiftUI

struct AddTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Exercise.name) private var availableExercises: [Exercise]
    @Query(sort: \WorkoutTemplate.createdAt) private var existingTemplates: [WorkoutTemplate]

    private let existingTemplate: WorkoutTemplate?
    private let isEditingMode: Bool
    private let initialSnapshot: TemplateDraftSnapshot

    @State private var title = ""
    @State private var exercises: [TemplateExerciseDraft] = []
    @State private var activeRestPicker: RestPickerContext?
    @State private var activeExercisePicker: ActiveExercisePicker?
    @State private var isShowingReorderSheet = false
    @State private var pendingRestSeconds = RestPickerContext.offValue
    @State private var templatePendingDeletion: WorkoutTemplate?
    @State private var isShowingDiscardAlert = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: FocusField?

    init(template: WorkoutTemplate? = nil, savesAsNewTemplate: Bool = false) {
        existingTemplate = savesAsNewTemplate ? nil : template
        isEditingMode = template != nil && !savesAsNewTemplate

        let initialTitle: String
        if savesAsNewTemplate, let template {
            initialTitle = "\(template.name) (copy)"
        } else {
            initialTitle = template?.name ?? "New Workout"
        }

        let initialExercises = template?.sortedExercises.map(TemplateExerciseDraft.init(templateExercise:)) ?? []

        _title = State(initialValue: initialTitle)
        _exercises = State(
            initialValue: initialExercises
        )
        initialSnapshot = TemplateDraftSnapshot(
            title: initialTitle,
            exercises: initialExercises.map(TemplateExerciseSnapshot.init)
        )
    }

    var body: some View {
        content
        .scrollDismissesKeyboard(.interactively)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
        }
        .navigationTitle(isEditingMode ? "Edit Template" : "Add Template")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .toolbar { toolbarContent }
        .sheet(item: $activeRestPicker) { context in
            restTimerSheet(for: context)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $activeExercisePicker, content: exercisePickerSheet)
        .sheet(isPresented: $isShowingReorderSheet, content: reorderSheet)
        .alert("Discard Template?", isPresented: $isShowingDiscardAlert) {
            Button("Keep Editing", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard this template?")
        }
        .alert(
            "Delete Template",
            isPresented: isShowingDeleteAlert,
            presenting: templatePendingDeletion,
            actions: { template in
                Button("Delete", role: .destructive) {
                    deleteTemplate(template)
                }
                Button("Cancel", role: .cancel) { }
            },
            message: { template in
                Text("Delete \(template.name)? This action cannot be undone.")
            }
        )
        .alert("Template Error", isPresented: isShowingError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if exercises.isEmpty {
            emptyStateContent
        } else {
            populatedContent
        }
    }

    private var emptyStateContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            titleCard
            Spacer(minLength: 0)
            emptyExercisesView
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var populatedContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                titleCard

                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    exerciseCard(exerciseIndex: index, exercise: exercise)
                }

                addExerciseLink
            }
            .padding(.vertical, 12)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                cancelTapped()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            settingsMenu
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                saveTemplate()
            }
            .disabled(!canSave)
        }

        ToolbarItemGroup(placement: .keyboard) {
            if focusedField != nil {
                Spacer()
                Button {
                    dismissKeyboard()
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                .accessibilityLabel("Hide keyboard")
            }
        }
    }

    private var settingsMenu: some View {
        Menu {
            Button("Reorder exercise", systemImage: "arrow.up.arrow.down") {
                isShowingReorderSheet = true
            }
            .disabled(exercises.isEmpty)

            Button("Settings", systemImage: "gearshape") { }
                .disabled(true)

            Button("Delete", systemImage: "trash", role: .destructive) {
                templatePendingDeletion = existingTemplate
            }
            .disabled(existingTemplate == nil)
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("Template settings")
    }

    private func exercisePickerSheet(for context: ActiveExercisePicker) -> some View {
        NavigationStack {
            ExercisePickerView(
                exercises: selectableExercises,
                initiallySelectedIDs: [],
                selectionMode: .single,
                allowsCustomExerciseCreation: true,
                actionTitle: context.actionTitle,
                onAddSelected: { selectedExerciseItems in
                    guard let selectedExercise = selectedExerciseItems.first else {
                        return
                    }
                    handleExercisePickerSelection(selectedExercise, context: context)
                }
            )
        }
    }

    private func reorderSheet() -> some View {
        TemplateExerciseReorderSheet(
            exercises: exercises,
            onSave: { reorderedExercises in
                exercises = reorderedExercises
                isShowingReorderSheet = false
            }
        )
    }

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Template name", text: $title)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.title2.bold())
                .focused($focusedField, equals: .title)

            Text(templateSummaryText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }

    private var emptyExercisesView: some View {
        ContentUnavailableView {
            Label("No Exercises Added", systemImage: "dumbbell")
        } description: {
            Text("Tap Add Exercises to start building this template.")
        } actions: {
            addExerciseLink
        }
        .frame(maxWidth: .infinity)
    }

    private var addExerciseLink: some View {
        NavigationLink {
            ExercisePickerView(
                exercises: selectableExercises,
                initiallySelectedIDs: Set(exercises.compactMap(\.exerciseID)),
                allowsCustomExerciseCreation: true,
                onAddSelected: { selectedExerciseItems in
                    addExercises(selectedExerciseItems)
                }
            )
        } label: {
            Label("Add Exercises", systemImage: "plus")
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .padding(.horizontal, 16)
    }

    private func exerciseCard(exerciseIndex: Int, exercise: TemplateExerciseDraft) -> some View {
        ExerciseCard(
            title: exercise.name,
            equipmentText: exerciseEquipmentText(for: exercise),
            horizontalPadding: 20,
            tableStyle: .template(showsRestTimer: exercise.showsRestTimer),
            showsRestTimerControl: true,
            isRestTimerActive: exercise.showsRestTimer,
            onToggleRestTimer: {
                withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                    exercises[exerciseIndex].showsRestTimer.toggle()
                }
            },
            showsMenu: true,
            addSetTitle: "Add Set",
            onAddSet: {
                withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                    addSet(to: exercise.id)
                }
            }
        ) {
            Button(exercise.notes.isEmpty && !exercise.notesVisible ? "Add Notes" : "Edit Notes", systemImage: "note.text") {
                exercises[exerciseIndex].notesVisible = true
            }

            Button("Replace", systemImage: "arrow.triangle.2.circlepath") {
                activeExercisePicker = .replace(exerciseID: exercise.id)
            }
            Button("Create superset", systemImage: "link") { }

            Divider()

            Button("Add exercise above", systemImage: "arrow.up") {
                activeExercisePicker = .insert(exerciseID: exercise.id, direction: .above)
            }
            Button("Add exercise below", systemImage: "arrow.down") {
                activeExercisePicker = .insert(exerciseID: exercise.id, direction: .below)
            }

            Divider()

            Button("Delete Exercise", systemImage: "trash", role: .destructive) {
                deleteExercise(exercise.id)
            }
        } notesContent: {
            if exercise.notesVisible || !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                TextField("Add routine notes here", text: $exercises[exerciseIndex].notes, axis: .vertical)
                    .lineLimit(nil)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .focused($focusedField, equals: .notes(exercise.id))
            }
        } rowsContent: {
            LazyVStack(spacing: 8) {
                ForEach(Array(exercises[exerciseIndex].sets.enumerated()), id: \.element.id) { setIndex, set in
                    setRow(
                        exerciseIndex: exerciseIndex,
                        setIndex: setIndex,
                        exerciseID: exercise.id,
                        setID: set.id
                    )
                    .transition(setRowTransition)
                }
            }
            .animation(.snappy(duration: 0.28, extraBounce: 0.03), value: exercises[exerciseIndex].sets.count)
        }
        .animation(.snappy(duration: 0.22, extraBounce: 0), value: exercise.showsRestTimer)
    }

    private func setRow(
        exerciseIndex: Int,
        setIndex: Int,
        exerciseID: UUID,
        setID: UUID
    ) -> some View {
        HStack(spacing: 10) {
            Menu {
                Picker("Set Type", selection: setTypeBinding(exerciseIndex: exerciseIndex, setIndex: setIndex)) {
                    ForEach(TemplateSetType.menuPrimaryCases, id: \.self) { type in
                        Label(type.menuTitle, systemImage: type.menuSystemImage)
                            .tag(type)
                    }
                    if setIndex > 0 {
                        Label(TemplateSetType.drop.menuTitle, systemImage: TemplateSetType.drop.menuSystemImage)
                            .tag(TemplateSetType.drop)
                    }
                }

                if setIndex == 0 {
                    Section {
                        Label(TemplateSetType.drop.menuTitle, systemImage: TemplateSetType.drop.menuSystemImage)
                            .tag(TemplateSetType.drop)
                            .disabled(true)
                    }
                }
            } label: {
                setTypeButton(
                    setNumber: displayedSetNumber(exerciseIndex: exerciseIndex, setIndex: setIndex),
                    type: exercises[exerciseIndex].sets[setIndex].type
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                setTypeAccessibilityLabel(
                    exerciseIndex: exerciseIndex,
                    for: setIndex,
                    type: exercises[exerciseIndex].sets[setIndex].type
                )
            )

            TextField("-", text: $exercises[exerciseIndex].sets[setIndex].weightText)
                .font(.headline.weight(.semibold))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 9))
                .focused($focusedField, equals: .weight(exerciseID, setID))

            TextField("-", text: $exercises[exerciseIndex].sets[setIndex].repsText)
                .font(.headline.weight(.semibold))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 9))
                .focused($focusedField, equals: .reps(exerciseID, setID))

            if exercises[exerciseIndex].showsRestTimer {
                Button {
                    presentRestPicker(for: exerciseID, setID: setID)
                } label: {
                    Text(restTimerLabel(for: exercises[exerciseIndex].sets[setIndex].restSeconds))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(exercises[exerciseIndex].sets[setIndex].restSeconds == nil ? .secondary : .primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.horizontal, 8)
                        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(restFieldAccessibilityLabel(for: exercises[exerciseIndex].sets[setIndex].restSeconds))
            }
        }
        .contentShape(Rectangle())
    }

    private func setTypeButton(setNumber: Int, type: TemplateSetType) -> some View {
        ZStack {
            Circle()
                .fill(type.rowBackgroundColor)

            Circle()
                .stroke(type.rowBorderColor, lineWidth: 1)

            if type == .normal {
                Text("\(setNumber)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
            } else {
                Image(systemName: type.rowSystemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(type.rowForegroundColor)
            }
        }
        .frame(width: 40, height: 40)
    }

    private func restTimerSheet(for context: RestPickerContext) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Rest", selection: $pendingRestSeconds) {
                    Text("Off").tag(RestPickerContext.offValue)
                    ForEach(RestPickerContext.values, id: \.self) { seconds in
                    Text(restTimerLabel(for: seconds))
                            .tag(seconds)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Rest Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        activeRestPicker = nil
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applyRestSelection(for: context)
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && !exercises.isEmpty
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

    private var selectableExercises: [ExercisePickerItem] {
        availableExercises.map(\.pickerItem)
    }

    private func addExercises(_ selectedItems: [ExercisePickerItem]) {
        var existingIDs = Set(exercises.compactMap(\.exerciseID))

        for item in selectedItems where existingIDs.insert(item.id).inserted {
            exercises.append(makeDraft(for: item))
        }
    }

    private func deleteExercise(_ exerciseID: UUID) {
        exercises.removeAll { $0.id == exerciseID }
    }

    private func handleExercisePickerSelection(_ exercise: ExercisePickerItem, context: ActiveExercisePicker) {
        switch context {
        case .replace(let exerciseID):
            replaceExercise(exerciseID, with: exercise)
        case .insert(let exerciseID, let direction):
            insertExercise(exercise, relativeTo: exerciseID, direction: direction)
        }
    }

    private func insertExercise(
        _ exercise: ExercisePickerItem,
        relativeTo targetExerciseID: UUID,
        direction: InsertExerciseDirection
    ) {
        guard !exercises.contains(where: { $0.exerciseID == exercise.id }),
              let index = exercises.firstIndex(where: { $0.id == targetExerciseID })
        else {
            return
        }

        let insertionIndex = switch direction {
        case .above:
            index
        case .below:
            index + 1
        }

        exercises.insert(makeDraft(for: exercise), at: insertionIndex)
    }

    private func replaceExercise(_ targetExerciseID: UUID, with exercise: ExercisePickerItem) {
        guard let index = exercises.firstIndex(where: { $0.id == targetExerciseID }) else {
            return
        }

        exercises[index].exerciseID = exercise.id
        exercises[index].name = exercise.name
    }

    private func addSet(to exerciseID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else {
            return
        }

        exercises[index].sets.append(.empty)
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        templatePendingDeletion = nil

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteSet(exerciseID: UUID, setID: UUID, animated: Bool = false) {
        guard let exerciseIndex = exercises.firstIndex(where: { $0.id == exerciseID }),
              exercises[exerciseIndex].sets.count > 1,
              let setIndex = exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID })
        else {
            return
        }

        let removeSet: () -> Void = {
            _ = exercises[exerciseIndex].sets.remove(at: setIndex)
            normalizeSetTypes(for: exerciseIndex)
        }

        if animated {
            withAnimation(.snappy(duration: 0.22, extraBounce: 0), removeSet)
        } else {
            removeSet()
        }
    }

    private func presentRestPicker(for exerciseID: UUID, setID: UUID) {
        guard let exerciseIndex = exercises.firstIndex(where: { $0.id == exerciseID }),
              let setIndex = exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID })
        else {
            return
        }

        pendingRestSeconds = exercises[exerciseIndex].sets[setIndex].restSeconds ?? RestPickerContext.offValue
        activeRestPicker = RestPickerContext(exerciseID: exerciseID, setID: setID)
    }

    private func applyRestSelection(for context: RestPickerContext) {
        guard let exerciseIndex = exercises.firstIndex(where: { $0.id == context.exerciseID }),
              let setIndex = exercises[exerciseIndex].sets.firstIndex(where: { $0.id == context.setID })
        else {
            activeRestPicker = nil
            return
        }

        exercises[exerciseIndex].sets[setIndex].restSeconds = pendingRestSeconds == RestPickerContext.offValue
            ? nil
            : pendingRestSeconds
        activeRestPicker = nil
    }

    private func updateSetType(_ type: TemplateSetType, exerciseIndex: Int, setIndex: Int) {
        exercises[exerciseIndex].sets[setIndex].type = normalizedSetType(type, for: setIndex)
    }

    private func setTypeBinding(exerciseIndex: Int, setIndex: Int) -> Binding<TemplateSetType> {
        Binding(
            get: { exercises[exerciseIndex].sets[setIndex].type },
            set: { newValue in
                updateSetType(newValue, exerciseIndex: exerciseIndex, setIndex: setIndex)
            }
        )
    }

    private func normalizeSetTypes(for exerciseIndex: Int) {
        exercises[exerciseIndex].sets = exercises[exerciseIndex].sets.enumerated().map { setIndex, set in
            var normalizedSet = set
            normalizedSet.type = normalizedSetType(set.type, for: setIndex)
            return normalizedSet
        }
    }

    private func restTimerLabel(for seconds: Int?) -> String {
        guard let seconds else { return "Off" }

        if seconds < 60 {
            return "\(seconds)s"
        }

        let minutes = seconds / 60
        let remainingSeconds = seconds % 60

        return "\(minutes)m \(remainingSeconds)s"
    }

    private func restFieldAccessibilityLabel(for seconds: Int?) -> String {
        "Rest timer \(restTimerLabel(for: seconds))"
    }

    private func setTypeAccessibilityLabel(
        exerciseIndex: Int,
        for setIndex: Int,
        type: TemplateSetType
    ) -> String {
        "Set \(displayedSetNumber(exerciseIndex: exerciseIndex, setIndex: setIndex)), \(type.menuTitle)"
    }

    private var exerciseCount: Int {
        exercises.count
    }

    private var setCount: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    private var templateSummaryText: String {
        "\(countText(exerciseCount, singular: "exercise")), \(countText(setCount, singular: "set"))"
    }

    private var setRowTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
            removal: .opacity.combined(with: .scale(scale: 0.94, anchor: .top))
        )
    }

    private func countText(_ count: Int, singular: String) -> String {
        count == 1 ? "1 \(singular)" : "\(count) \(singular)s"
    }

    private func exerciseEquipmentText(for exercise: TemplateExerciseDraft) -> String? {
        if let catalogExercise = catalogExercise(for: exercise.exerciseID) {
            let trimmedEquipment = catalogExercise.equipment.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedEquipment.isEmpty {
                return trimmedEquipment
            }
        }

        let inferredEquipment = ExerciseEquipment.infer(
            equipment: "",
            exerciseName: exercise.name
        )

        return inferredEquipment == .other ? nil : inferredEquipment.rawValue
    }

    private func makeDraft(for exercise: ExercisePickerItem) -> TemplateExerciseDraft {
        TemplateExerciseDraft(
            exerciseID: exercise.id,
            name: exercise.name,
            equipment: exercise.equipment.rawValue,
            notes: "",
            notesVisible: false,
            showsRestTimer: false,
            sets: [.empty]
        )
    }

    private func catalogExercise(for exerciseID: PersistentIdentifier?) -> Exercise? {
        guard let exerciseID else {
            return nil
        }

        return availableExercises.first { $0.persistentModelID == exerciseID }
    }

    private func normalizedSetType(_ type: TemplateSetType, for setIndex: Int) -> TemplateSetType {
        if setIndex == 0, type == .drop {
            return .normal
        }

        return type
    }

    private func displayedSetNumber(exerciseIndex: Int, setIndex: Int) -> Int {
        let countedSets = exercises[exerciseIndex].sets
            .prefix(setIndex + 1)
            .reduce(into: 0) { partialResult, set in
                if set.type.countsTowardDisplayedSetNumber {
                    partialResult += 1
                }
            }

        return max(countedSets, 1)
    }

    private func saveTemplate() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !exercises.isEmpty else {
            return
        }

        guard !hasDuplicateName(trimmedTitle) else {
            errorMessage = "A template named \(trimmedTitle) already exists."
            return
        }

        let template = existingTemplate ?? WorkoutTemplate(name: trimmedTitle)
        
        template.name = trimmedTitle

        if existingTemplate == nil {
            modelContext.insert(template)
        } else {
            let existingEntries = template.exercises
            template.exercises.removeAll()
            for entry in existingEntries {
                modelContext.delete(entry)
            }
        }

        let newExercises = exercises.enumerated().map { index, exerciseDraft in
            let templateExercise = TemplateExercise(
                position: index + 1,
                targetSets: max(exerciseDraft.sets.count, 1),
                targetReps: overallRepTarget(for: exerciseDraft.sets),
                restSeconds: overallRestDuration(for: exerciseDraft.sets),
                notes: exerciseDraft.notes,
                template: template,
                exercise: catalogExercise(for: exerciseDraft.exerciseID)
            )

            templateExercise.prescribedSets = exerciseDraft.sets.enumerated().map { setIndex, setDraft in
                let parsedRepTarget = parseRepTarget(setDraft.repsText)
                return TemplateExerciseSet(
                    position: setIndex + 1,
                    prescribedWeight: parseWeight(setDraft.weightText),
                    targetReps: parsedRepTarget.exact,
                    targetRepMin: parsedRepTarget.min,
                    targetRepMax: parsedRepTarget.max,
                    restSeconds: setDraft.restSeconds ?? 0,
                    typeRawValue: normalizedSetType(setDraft.type, for: setIndex).rawValue,
                    templateExercise: templateExercise
                )
            }

            return templateExercise
        }

        template.exercises = newExercises

        for exercise in newExercises {
            modelContext.insert(exercise)

            for set in exercise.prescribedSets {
                modelContext.insert(set)
            }
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func hasDuplicateName(_ title: String) -> Bool {
        existingTemplates.contains { template in
            if let existingTemplate, template.persistentModelID == existingTemplate.persistentModelID {
                return false
            }

            return template.name.compare(title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private func overallRepTarget(for sets: [TemplateSetDraft]) -> String {
        let values = sets
            .map(\.repsText)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let first = values.first else {
            return ""
        }

        return values.allSatisfy { $0 == first } ? first : "Variable"
    }

    private func overallRestDuration(for sets: [TemplateSetDraft]) -> Int {
        let values = sets.compactMap(\.restSeconds).filter { $0 > 0 }

        guard let first = values.first, values.count == sets.count else {
            return 0
        }

        return values.allSatisfy { $0 == first } ? first : 0
    }

    private func parseWeight(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private func parseRepTarget(_ text: String) -> (exact: Int?, min: Int?, max: Int?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (nil, nil, nil)
        }

        if let exact = Int(trimmed) {
            return (exact, nil, nil)
        }

        let separators = CharacterSet(charactersIn: "-–")
        let parts = trimmed.components(separatedBy: separators).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if parts.count == 2,
           let min = Int(parts[0]),
           let max = Int(parts[1]) {
            return (nil, min, max)
        }

        return (nil, nil, nil)
    }

    private func cancelTapped() {
        if !hasUnsavedChanges {
            dismiss()
        } else {
            isShowingDiscardAlert = true
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
    }

    private var hasUnsavedChanges: Bool {
        TemplateDraftSnapshot(
            title: title,
            exercises: exercises.map(TemplateExerciseSnapshot.init)
        ) != initialSnapshot
    }
}

private enum FocusField: Hashable {
    case title
    case notes(UUID)
    case weight(UUID, UUID)
    case reps(UUID, UUID)
}

struct TemplateExerciseDraft: Identifiable {
    let id: UUID
    var exerciseID: PersistentIdentifier?
    var name: String
    var equipment: String
    var notes: String
    var notesVisible: Bool
    var showsRestTimer: Bool
    var sets: [TemplateSetDraft]

    init(
        id: UUID = UUID(),
        exerciseID: PersistentIdentifier?,
        name: String,
        equipment: String,
        notes: String,
        notesVisible: Bool,
        showsRestTimer: Bool,
        sets: [TemplateSetDraft]
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.name = name
        self.equipment = equipment
        self.notes = notes
        self.notesVisible = notesVisible
        self.showsRestTimer = showsRestTimer
        self.sets = sets
    }

    init(templateExercise: TemplateExercise) {
        let exerciseID = templateExercise.exercise?.persistentModelID
        let fallbackRestSeconds = templateExercise.restSeconds == 0 ? nil : templateExercise.restSeconds
        let sets: [TemplateSetDraft]

        if templateExercise.sortedPrescribedSets.isEmpty {
            sets = (0..<max(templateExercise.targetSets, 1)).map { setIndex in
                TemplateSetDraft(
                    repsText: templateExercise.targetReps
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                    restSeconds: fallbackRestSeconds,
                    type: .normal
                )
            }
        } else {
            sets = templateExercise.sortedPrescribedSets.enumerated().map { setIndex, set in
                TemplateSetDraft(
                    weightText: set.displayWeightText,
                    repsText: set.displayRepText,
                    restSeconds: set.effectiveRestSeconds == 0 ? nil : set.effectiveRestSeconds,
                    type: setIndex == 0 && set.setType == .drop ? .normal : set.setType
                )
            }
        }

        self.init(
            exerciseID: exerciseID,
            name: templateExercise.displayName,
            equipment: templateExercise.exercise?.equipment ?? "",
            notes: templateExercise.notes,
            notesVisible: !templateExercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            showsRestTimer: sets.contains { $0.restSeconds != nil },
            sets: sets
        )
    }
}

private struct TemplateDraftSnapshot: Equatable {
    let title: String
    let exercises: [TemplateExerciseSnapshot]
}

private struct TemplateExerciseSnapshot: Equatable {
    let exerciseID: PersistentIdentifier?
    let name: String
    let notes: String
    let showsRestTimer: Bool
    let sets: [TemplateSetSnapshot]

    init(_ draft: TemplateExerciseDraft) {
        exerciseID = draft.exerciseID
        name = draft.name
        notes = draft.notes
        showsRestTimer = draft.showsRestTimer
        sets = draft.sets.map(TemplateSetSnapshot.init)
    }
}

struct TemplateSetDraft: Identifiable {
    let id: UUID
    var weightText: String
    var repsText: String
    var restSeconds: Int?
    var type: TemplateSetType

    init(
        id: UUID = UUID(),
        weightText: String = "",
        repsText: String = "",
        restSeconds: Int? = nil,
        type: TemplateSetType = .normal
    ) {
        self.id = id
        self.weightText = weightText
        self.repsText = repsText
        self.restSeconds = restSeconds
        self.type = type
    }

    static var empty: TemplateSetDraft {
        TemplateSetDraft()
    }
}

private struct TemplateSetSnapshot: Equatable {
    let weightText: String
    let repsText: String
    let restSeconds: Int?
    let type: TemplateSetType

    init(_ draft: TemplateSetDraft) {
        weightText = draft.weightText
        repsText = draft.repsText
        restSeconds = draft.restSeconds
        type = draft.type
    }
}

private struct RestPickerContext: Identifiable {
    static let offValue = -1
    static let values = Array(stride(from: 5, through: 300, by: 5))

    let exerciseID: UUID
    let setID: UUID

    var id: UUID { setID }
}

private enum ActiveExercisePicker: Identifiable {
    case replace(exerciseID: UUID)
    case insert(exerciseID: UUID, direction: InsertExerciseDirection)

    var id: String {
        switch self {
        case .replace(let exerciseID):
            "replace-\(exerciseID.uuidString)"
        case .insert(let exerciseID, let direction):
            "insert-\(exerciseID.uuidString)-\(direction.rawValue)"
        }
    }

    var actionTitle: String {
        switch self {
        case .replace:
            "Replace"
        case .insert:
            "Add"
        }
    }
}

private enum InsertExerciseDirection: String {
    case above
    case below
}

#Preview("Filled Template") {
    AddTemplateSheetPreview(template: IronRecordPreview.sampleTemplate)
    .modelContainer(IronRecordPreview.container)
}

#Preview("Empty Template") {
    AddTemplateSheetPreview()
    .modelContainer(IronRecordPreview.container)
}

private struct AddTemplateSheetPreview: View {
    let template: WorkoutTemplate?

    @State private var isPresented = true

    init(template: WorkoutTemplate? = nil) {
        self.template = template
    }

    var body: some View {
        Color(.systemGroupedBackground)
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    AddTemplateView(template: template)
                }
            }
    }
}
