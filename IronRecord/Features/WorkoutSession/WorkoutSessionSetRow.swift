import SwiftUI

struct WorkoutSessionSetRow: View {
    let session: WorkoutSession
    let exercisePosition: Int
    let sessionSet: WorkoutSessionSet
    let isPaused: Bool
    let showsRestDetails: Bool
    let onSave: () -> Void
    let onToggleDone: (Bool) -> Void

    @State private var weightText: String
    @State private var repsText: String
    @State private var selectedType: TemplateSetType

    init(
        session: WorkoutSession,
        exercisePosition: Int,
        sessionSet: WorkoutSessionSet,
        isPaused: Bool,
        showsRestDetails: Bool,
        onSave: @escaping () -> Void,
        onToggleDone: @escaping (Bool) -> Void
    ) {
        self.session = session
        self.exercisePosition = exercisePosition
        self.sessionSet = sessionSet
        self.isPaused = isPaused
        self.showsRestDetails = showsRestDetails
        self.onSave = onSave
        self.onToggleDone = onToggleDone
        _weightText = State(initialValue: sessionSet.loggedWeightText)
        _repsText = State(initialValue: sessionSet.loggedRepsText)
        _selectedType = State(initialValue: sessionSet.setType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Menu {
                    Picker("Set Type", selection: $selectedType) {
                        ForEach(TemplateSetType.menuPrimaryCases, id: \.self) { type in
                            Label(type.menuTitle, systemImage: type.menuSystemImage)
                                .tag(type)
                        }

                        if sessionSet.position > 1 {
                            Label(TemplateSetType.drop.menuTitle, systemImage: TemplateSetType.drop.menuSystemImage)
                                .tag(TemplateSetType.drop)
                        }
                    }

                    if sessionSet.position == 1 {
                        Section {
                            Label(TemplateSetType.drop.menuTitle, systemImage: TemplateSetType.drop.menuSystemImage)
                                .tag(TemplateSetType.drop)
                                .disabled(true)
                        }
                    }
                } label: {
                    setTypeBadge
                }
                .buttonStyle(.plain)
                .disabled(isPaused)
                .onChange(of: selectedType) {
                    sessionSet.setType = normalizedSetType(selectedType)
                    selectedType = sessionSet.setType
                    onSave()
                }

                TextField("KG", text: $weightText)
                    .font(.headline)
                    .bold()
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .disabled(isPaused)
                    .onChange(of: weightText) {
                        sessionSet.loggedWeight = parseWeight(weightText)
                        onSave()
                    }

                TextField("REPS", text: $repsText)
                    .font(.headline)
                    .bold()
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .disabled(isPaused)
                    .onChange(of: repsText) {
                        sessionSet.loggedReps = Int(repsText)
                        onSave()
                    }

                Button {
                    onToggleDone(!sessionSet.isCompleted)
                } label: {
                    ZStack {
                        Circle()
                            .fill(sessionSet.isCompleted ? Color.accentColor : Color.clear)

                        Circle()
                            .stroke(
                                sessionSet.isCompleted ? Color.accentColor : Color.secondary.opacity(0.35),
                                lineWidth: 1.5
                            )

                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(sessionSet.isCompleted ? Color.white : Color.secondary.opacity(0.8))
                    }
                }
                .frame(width: 40, height: 40)
                .buttonStyle(.plain)
                .disabled(isPaused)
                .accessibilityLabel(sessionSet.isCompleted ? "Mark set incomplete" : "Mark set complete")
            }

            if showsRestDetails, sessionSet.effectiveRestSeconds > 0 {
                restStrip
            }
        }
    }

    private var setTypeBadge: some View {
        ZStack {
            Circle()
                .fill(sessionSet.setType.rowBackgroundColor)

            Circle()
                .stroke(sessionSet.setType.rowBorderColor, lineWidth: 1)

            if sessionSet.setType == .normal {
                Text("\(displayedSetNumber)")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.primary)
            } else {
                Image(systemName: sessionSet.setType.rowSystemImage)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(sessionSet.setType.rowForegroundColor)
            }
        }
        .frame(width: 40, height: 40)
        .accessibilityLabel("Set \(displayedSetNumber), \(sessionSet.setType.menuTitle)")
    }

    private var restStrip: some View {
        let restIdentifier = WorkoutRestIdentifier(
            exercisePosition: exercisePosition,
            setPosition: sessionSet.position
        )
        let isActiveRest = session.activeRestIdentifier == restIdentifier

        return Group {
            if isActiveRest {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let remainingSeconds = session.activeRestRemainingSeconds(at: context.date) ?? 0
                    restLabel(
                        text: WorkoutSessionTimerState.formatClock(seconds: remainingSeconds),
                        isActive: remainingSeconds > 0
                    )
                }
            } else {
                restLabel(
                    text: WorkoutSessionTimerState.formatClock(seconds: sessionSet.effectiveRestSeconds),
                    isActive: false
                )
            }
        }
    }

    private func restLabel(text: String, isActive: Bool) -> some View {
        Label {
            Text("Rest \(text)")
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
        } icon: {
            Image(systemName: isActive ? "timer.circle.fill" : "timer")
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (isActive ? Color.accentColor.opacity(0.1) : Color(.tertiarySystemBackground)),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    private var displayedSetNumber: Int {
        let countedSets = sessionSet.sessionExercise?.sortedSets
            .prefix { $0.position <= sessionSet.position }
            .filter { $0.setType.countsTowardDisplayedSetNumber } ?? []

        return max(countedSets.count, 1)
    }

    private func normalizedSetType(_ type: TemplateSetType) -> TemplateSetType {
        if sessionSet.position == 1, type == .drop {
            return .normal
        }

        return type
    }

    private func parseWeight(_ value: String) -> Double? {
        let normalizedValue = value.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedValue)
    }
}
