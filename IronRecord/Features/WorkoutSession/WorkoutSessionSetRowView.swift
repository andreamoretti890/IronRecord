import SwiftUI

struct WorkoutSessionSetRowView: View {
    let set: WorkoutSessionSet
    let onPersist: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(set.position)")
                .font(.title3.weight(.semibold))
                .frame(width: 40, alignment: .center)

            Text("-")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            TextField(weightPlaceholder, text: actualWeightBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(.tertiary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))

            TextField(repsPlaceholder, text: actualRepsBinding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(.tertiary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))

            Button {
                set.isCompleted.toggle()
                onPersist()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark" : "")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(set.isCompleted ? .white : .clear)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(set.isCompleted ? Color.accentColor : Color(.systemGray4))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.isCompleted ? "Mark set incomplete" : "Mark set complete")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private var actualWeightBinding: Binding<String> {
        Binding(
            get: { set.actualWeightText },
            set: { newValue in
                set.actualWeightText = newValue
                onPersist()
            }
        )
    }

    private var actualRepsBinding: Binding<String> {
        Binding(
            get: { set.actualRepsText },
            set: { newValue in
                set.actualRepsText = newValue
                onPersist()
            }
        )
    }

    private var weightPlaceholder: String {
        return set.plannedWeightText.isEmpty ? "-" : set.plannedWeightText
    }

    private var repsPlaceholder: String {
        return set.plannedRepTargetText.isEmpty ? "-" : set.plannedRepTargetText
    }

    private var rowBackground: Color {
        return set.isCompleted ? Color.accentColor.opacity(0.14) : Color(.secondarySystemBackground)
    }
}
