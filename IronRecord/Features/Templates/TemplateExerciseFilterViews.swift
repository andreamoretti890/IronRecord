import SwiftUI

struct FilterChip: View {
    let title: String
    let isActive: Bool
    let showsChevron: Bool
    let tintText: Bool
    let action: () -> Void

    init(
        title: String,
        isActive: Bool,
        showsChevron: Bool = true,
        tintText: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isActive = isActive
        self.showsChevron = showsChevron
        self.tintText = tintText
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .lineLimit(1)
                if showsChevron {
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
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
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            isActive || tintText
                ? Color.accentColor
                : Color.primary
        )
    }
}

struct FilterSelectionSheet: View {
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
