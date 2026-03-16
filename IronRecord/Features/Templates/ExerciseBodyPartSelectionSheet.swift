import SwiftUI

enum ExerciseOptionSelectionMode {
    case single
    case multiple
}

struct ExerciseOptionSelectionSheet<Option: Identifiable & Hashable>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let options: [Option]
    let selectionMode: ExerciseOptionSelectionMode
    let initialSelection: Set<Option>
    let allowsEmptySelection: Bool
    let optionTitle: (Option) -> String
    let onSave: (Set<Option>) -> Void

    @State private var selection: Set<Option>

    init(
        title: String,
        options: [Option],
        selectionMode: ExerciseOptionSelectionMode,
        initialSelection: Set<Option>,
        allowsEmptySelection: Bool,
        optionTitle: @escaping (Option) -> String,
        onSave: @escaping (Set<Option>) -> Void
    ) {
        self.title = title
        self.options = options
        self.selectionMode = selectionMode
        self.initialSelection = initialSelection
        self.allowsEmptySelection = allowsEmptySelection
        self.optionTitle = optionTitle
        self.onSave = onSave
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(options) { option in
                    selectorRow(for: option)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onSave(selection)
                    dismiss()
                }
                .disabled(selection.isEmpty && !allowsEmptySelection)
            }
        }
    }

    private func selectorRow(for option: Option) -> some View {
        let isSelected = selection.contains(option)

        return Button {
            toggleSelection(for: option)
        } label: {
            HStack(spacing: 12) {
                Text(optionTitle(option))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                selectionIndicator(isSelected: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.12)
                    : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.6) : Color(.separator),
                        lineWidth: 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(optionTitle(option))
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 28, height: 28)

            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.45),
                    lineWidth: 1.5
                )
                .frame(width: 28, height: 28)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityHidden(true)
    }

    private func toggleSelection(for option: Option) {
        switch selectionMode {
        case .single:
            if selection.contains(option), allowsEmptySelection {
                selection.remove(option)
            } else {
                selection = [option]
            }
        case .multiple:
            if selection.contains(option) {
                selection.remove(option)
            } else {
                selection.insert(option)
            }
        }
    }
}
