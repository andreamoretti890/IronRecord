import SwiftUI

struct ExerciseCard<MenuContent: View, NotesContent: View, RowsContent: View>: View {
    enum TableStyle {
        case template(showsRestTimer: Bool)
        case activeWorkout
    }

    let title: String
    let equipmentText: String?
    let horizontalPadding: CGFloat
    let showsBadge: Bool
    let tableStyle: TableStyle
    let showsRestTimerControl: Bool
    let isRestTimerActive: Bool
    let onToggleRestTimer: (() -> Void)?
    let showsMenu: Bool
    let addSetTitle: String?
    let onAddSet: (() -> Void)?
    @ViewBuilder let menuContent: () -> MenuContent
    @ViewBuilder let notesContent: () -> NotesContent
    @ViewBuilder let rowsContent: () -> RowsContent

    init(
        title: String,
        equipmentText: String? = nil,
        horizontalPadding: CGFloat = 0,
        showsBadge: Bool = true,
        tableStyle: TableStyle,
        showsRestTimerControl: Bool = false,
        isRestTimerActive: Bool = false,
        onToggleRestTimer: (() -> Void)? = nil,
        showsMenu: Bool = false,
        addSetTitle: String? = nil,
        onAddSet: (() -> Void)? = nil,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder notesContent: @escaping () -> NotesContent,
        @ViewBuilder rowsContent: @escaping () -> RowsContent
    ) {
        self.title = title
        self.equipmentText = equipmentText
        self.horizontalPadding = horizontalPadding
        self.showsBadge = showsBadge
        self.tableStyle = tableStyle
        self.showsRestTimerControl = showsRestTimerControl
        self.isRestTimerActive = isRestTimerActive
        self.onToggleRestTimer = onToggleRestTimer
        self.showsMenu = showsMenu
        self.addSetTitle = addSetTitle
        self.onAddSet = onAddSet
        self.menuContent = menuContent
        self.notesContent = notesContent
        self.rowsContent = rowsContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            notesContent()
            tableHeader
            rowsContent()
            if let addSetTitle, let onAddSet {
                Button(action: onAddSet) {
                    Label(addSetTitle, systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .foregroundStyle(.primary)
                        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, horizontalPadding)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            if showsBadge {
                initialsBadge
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.tint)

                if let equipmentText, !equipmentText.isEmpty {
                    Text(equipmentText)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsRestTimerControl {
                Button {
                    onToggleRestTimer?()
                } label: {
                    Image(systemName: "timer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isRestTimerActive ? Color.accentColor : .secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            (isRestTimerActive ? Color.accentColor.opacity(0.14) : Color(.tertiarySystemBackground)),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .disabled(onToggleRestTimer == nil)
                .accessibilityLabel(isRestTimerActive ? "Hide rest timers" : "Show rest timers")
            }

            if showsMenu {
                Menu {
                    menuContent()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(
                            Color(.tertiarySystemBackground),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 10) {
            Text("SET")
                .frame(width: 40, alignment: .center)

            Text("KG")
                .frame(maxWidth: .infinity)

            Text("REPS")
                .frame(maxWidth: .infinity)

            switch tableStyle {
            case .template(let showsRestTimer):
                if showsRestTimer {
                    Text("REST")
                        .frame(maxWidth: .infinity)
                }
            case .activeWorkout:
                Text("DONE")
                    .frame(width: 44)
            }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private var initialsBadge: some View {
        Circle()
            .fill(Color(.tertiarySystemBackground))
            .frame(width: 44, height: 44)
            .overlay {
                Text(initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
    }

    private var initials: String {
        let words = title
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(2)

        let joined = words
            .compactMap(\.first)
            .map(String.init)
            .joined()

        if joined.isEmpty {
            return "EX"
        }

        return joined.uppercased()
    }
}

#Preview("ExerciseCard Header - Circular Menu Button") {
    ExerciseCard(
        title: "Barbell Bench Press",
        equipmentText: "Barbell, Bench",
        horizontalPadding: 16,
        showsBadge: true,
        tableStyle: .activeWorkout,
        showsRestTimerControl: true,
        isRestTimerActive: false,
        onToggleRestTimer: {},
        showsMenu: true,
        addSetTitle: "Add Set",
        onAddSet: {},
        menuContent: {
            Button("Edit", action: {})
            Button("Delete", role: .destructive, action: {})
        },
        notesContent: {
            Text("Keep elbows at 45°.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        },
        rowsContent: {
            EmptyView()
        }
    )
    .padding()
}
