import SwiftData
import SwiftUI

struct CreateCustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onSave: (Exercise) -> Void

    @State private var name = ""
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var primaryBodyParts: Set<ExerciseBodyPart> = []
    @State private var secondaryBodyParts: Set<ExerciseBodyPart> = []
    @State private var activeSheet: CustomExerciseSheet?
    @State private var errorMessage: String?
    @FocusState private var isNameFieldFocused: Bool

    init(
        initialName: String = "",
        initialEquipment: ExerciseEquipment? = nil,
        initialPrimaryBodyParts: [ExerciseBodyPart] = [],
        initialSecondaryBodyParts: [ExerciseBodyPart] = [],
        onSave: @escaping (Exercise) -> Void = { _ in }
    ) {
        _name = State(initialValue: initialName)
        _selectedEquipment = State(initialValue: initialEquipment)
        _primaryBodyParts = State(initialValue: Set(initialPrimaryBodyParts))
        _secondaryBodyParts = State(initialValue: Set(initialSecondaryBodyParts))
        self.onSave = onSave
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                inputSection(
                    title: "Exercise Name"
                ) {
                    TextField("New exercise", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isNameFieldFocused)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.separator), lineWidth: 1)
                        }
                }

                inputSection(
                    title: "Equipment"
                ) {
                    selectorTriggerButton(
                        title: selectedEquipment?.rawValue ?? "Select equipment",
                        isSelected: selectedEquipment != nil,
                        action: {
                            activeSheet = .equipment
                        }
                    )
                }

                selectionSection(
                    title: "Primary Muscles",
                    caption: "Select one or more main muscles for this exercise.",
                    selectedBodyParts: orderedBodyParts(primaryBodyParts),
                    placeholder: "Select primary muscles",
                    onRemoveBodyPart: { bodyPart in
                        primaryBodyParts.remove(bodyPart)
                    },
                    action: {
                        activeSheet = .primary
                    }
                )

                selectionSection(
                    title: "Secondary Muscles",
                    caption: "Optional support muscles. They cannot overlap with primary muscles.",
                    selectedBodyParts: orderedBodyParts(secondaryBodyParts),
                    placeholder: "Select secondary muscles",
                    onRemoveBodyPart: { bodyPart in
                        secondaryBodyParts.remove(bodyPart)
                    },
                    action: {
                        activeSheet = .secondary
                    }
                )
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Custom Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCustomExercise()
                }
                .disabled(!canSave)
            }
        }
        .alert("Create Exercise Error", isPresented: isShowingError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .equipment:
                    ExerciseOptionSelectionSheet(
                        title: "Equipment",
                        options: ExerciseEquipment.filterOrder,
                        selectionMode: .single,
                        initialSelection: selectedEquipment.map { Set([$0]) } ?? [],
                        allowsEmptySelection: true,
                        optionTitle: \.rawValue,
                        onSave: { selection in
                            selectedEquipment = orderedEquipmentSelection(from: selection).first
                        }
                    )
                case .primary:
                    ExerciseOptionSelectionSheet(
                        title: "Primary Muscles",
                        options: primarySelectionOptions,
                        selectionMode: .multiple,
                        initialSelection: primaryBodyParts,
                        allowsEmptySelection: false,
                        optionTitle: \.rawValue,
                        onSave: { selection in
                            primaryBodyParts = selection
                        }
                    )
                case .secondary:
                    ExerciseOptionSelectionSheet(
                        title: "Secondary Muscles",
                        options: secondarySelectionOptions,
                        selectionMode: .multiple,
                        initialSelection: secondaryBodyParts,
                        allowsEmptySelection: true,
                        optionTitle: \.rawValue,
                        onSave: { selection in
                            secondaryBodyParts = selection
                        }
                    )
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .interactiveDismissDisabled()
        .onAppear {
            isNameFieldFocused = true
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedEquipment != nil &&
        !primaryBodyParts.isEmpty
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

    private var primarySelectionOptions: [ExerciseBodyPart] {
        ExerciseBodyPart.filterOrder.filter { bodyPart in
            secondaryBodyParts.contains(bodyPart) == false
        }
    }

    private var secondarySelectionOptions: [ExerciseBodyPart] {
        ExerciseBodyPart.filterOrder.filter { bodyPart in
            primaryBodyParts.contains(bodyPart) == false
        }
    }

    private func inputSection<Content: View>(
        title: String,
        caption: String = "",
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title)

            if !caption.isEmpty {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            content()
        }
    }

    private func selectionSection(
        title: String,
        caption: String,
        selectedBodyParts: [ExerciseBodyPart],
        placeholder: String,
        onRemoveBodyPart: @escaping (ExerciseBodyPart) -> Void,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title)

            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)

            selectorTriggerButton(
                title: selectedBodyParts.isEmpty ? placeholder : "Update selection",
                isSelected: !selectedBodyParts.isEmpty,
                action: action
            )
            
            if !selectedBodyParts.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(selectedBodyParts) { bodyPart in
                            removableChip(
                                title: bodyPart.rawValue,
                                onRemove: {
                                    onRemoveBodyPart(bodyPart)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func selectorTriggerButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func removableChip(
        title: String,
        onRemove: @escaping () -> Void
    ) -> some View {
        Button(action: onRemove) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)

                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.accentColor.opacity(0.28), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .accessibilityLabel("Remove \(title)")
    }

    private func orderedEquipmentSelection(from selection: Set<ExerciseEquipment>) -> [ExerciseEquipment] {
        ExerciseEquipment.filterOrder.filter(selection.contains)
    }

    private func orderedBodyParts(_ selection: Set<ExerciseBodyPart>) -> [ExerciseBodyPart] {
        ExerciseBodyPart.filterOrder.filter(selection.contains)
    }

    private func saveCustomExercise() {
        guard let selectedEquipment else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let orderedPrimaryBodyParts = orderedBodyParts(primaryBodyParts)
        let orderedSecondaryBodyParts = orderedBodyParts(secondaryBodyParts)

        guard !trimmedName.isEmpty, !orderedPrimaryBodyParts.isEmpty else {
            return
        }

        let exercise = Exercise(
            name: trimmedName,
            category: "Custom",
            primaryBodyParts: orderedPrimaryBodyParts,
            secondaryBodyParts: orderedSecondaryBodyParts,
            equipment: selectedEquipment.rawValue
        )

        modelContext.insert(exercise)

        do {
            try modelContext.save()
            onSave(exercise)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum CustomExerciseSheet: String, Identifiable {
    case equipment
    case primary
    case secondary

    var id: String { rawValue }
}

#Preview("Standard Flow") {
    CreateCustomExercisePreviewHost()
        .modelContainer(IronRecordPreview.container)
}

private struct CreateCustomExercisePreviewHost: View {
    @State private var isPresented = true

    var body: some View {
        Color(.systemGroupedBackground)
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    CreateCustomExerciseView(
                        initialName: "Biceps Curl",
                        initialEquipment: .dumbbellDouble,
                        initialPrimaryBodyParts: [.biceps, .forearms]
                    )
                }
            }
    }
}
