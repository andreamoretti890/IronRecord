import SwiftUI

struct WorkoutSessionExerciseCardView: View {
    let exercise: WorkoutSessionExercise
    let onAddSet: () -> Void
    let onDeleteExtraSet: (WorkoutSessionSet) -> Void
    let onPersist: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            TextField("Add notes here...", text: notesBinding, axis: .vertical)
                .lineLimit(2 ... 4)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 10) {
                Image(systemName: "timer")
                Text("Rest Timer: \(restTimerLabel)")
                Spacer()
            }
            .font(.headline)
            .foregroundStyle(.tint)

            setTableHeader

            List {
                ForEach(exercise.sortedSets) { set in
                    WorkoutSessionSetRowView(set: set, onPersist: onPersist)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if set.isExtraSet {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    onDeleteExtraSet(set)
                                }
                            }
                        }
                        .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .frame(height: listHeight)

            Button {
                onAddSet()
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.primary)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 28))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 58, height: 58)
                .overlay {
                    Text(initials(from: exercise.nameSnapshot))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.secondary)
                }

            Text(exercise.nameSnapshot)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { exercise.notes },
            set: { newValue in
                exercise.notes = newValue
                onPersist()
            }
        )
    }

    private var setTableHeader: some View {
        HStack(spacing: 12) {
            Text("SET")
                .frame(width: 40, alignment: .center)

            Text("PREVIOUS")
                .frame(maxWidth: .infinity)

            Text("KG")
                .frame(maxWidth: .infinity)

            Text("REPS")
                .frame(maxWidth: .infinity)

            Image(systemName: "checkmark")
                .frame(width: 52)
        }
        .font(.headline)
        .foregroundStyle(.secondary)
    }

    private var restTimerLabel: String {
        guard exercise.restSeconds > 0 else {
            return "Off"
        }

        if exercise.restSeconds < 60 {
            return "\(exercise.restSeconds)s"
        }

        let minutes = exercise.restSeconds / 60
        let seconds = exercise.restSeconds % 60
        return "\(minutes)m \(seconds)s"
    }

    private var listHeight: CGFloat {
        max(64, CGFloat(exercise.sortedSets.count) * 72)
    }

    private func initials(from name: String) -> String {
        let joined = name
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return joined.isEmpty ? "EX" : joined.uppercased()
    }
}
