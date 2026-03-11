import SwiftUI

struct TemplateRowView: View {
    let template: TemplateRowItem
    let onEditTapped: () -> Void
    let onDuplicateTapped: () -> Void
    let onDeleteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(template.title)
                    .font(.headline)

                Spacer(minLength: 8)

                Menu {
                    Button("Edit", systemImage: "pencil") {
                        onEditTapped()
                    }
                    Button("Duplicate", systemImage: "square.on.square") {
                        onDuplicateTapped()
                    }
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

struct TemplateRowItem: Identifiable {
    let id: UUID
    let title: String
    let exercises: [TemplateExerciseRowItem]

    init(id: UUID = UUID(), title: String, exercises: [TemplateExerciseRowItem]) {
        self.id = id
        self.title = title
        self.exercises = exercises
    }

    var exercisePreview: String {
        exercises.map(\.name).joined(separator: ", ")
    }

    static let mock: [TemplateRowItem] = [
        TemplateRowItem(
            title: "Push Day A",
            exercises: [
                TemplateExerciseRowItem(
                    name: "Barbell Bench Press",
                    notes: "Keep shoulder blades pinned back.",
                    restSeconds: 120,
                    sets: [
                        TemplateSetRowItem(weightText: "60", repsText: "8"),
                        TemplateSetRowItem(weightText: "60", repsText: "8"),
                        TemplateSetRowItem(weightText: "57.5", repsText: "10")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Incline Dumbbell Press",
                    notes: "",
                    restSeconds: 90,
                    sets: [
                        TemplateSetRowItem(weightText: "24", repsText: "10"),
                        TemplateSetRowItem(weightText: "24", repsText: "10"),
                        TemplateSetRowItem(weightText: "22", repsText: "12")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Seated Shoulder Press",
                    notes: "",
                    restSeconds: 90,
                    sets: [
                        TemplateSetRowItem(weightText: "18", repsText: "10"),
                        TemplateSetRowItem(weightText: "18", repsText: "10"),
                        TemplateSetRowItem(weightText: "16", repsText: "12")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Cable Lateral Raise",
                    notes: "Controlled eccentric.",
                    restSeconds: 60,
                    sets: [
                        TemplateSetRowItem(weightText: "7.5", repsText: "14"),
                        TemplateSetRowItem(weightText: "7.5", repsText: "14"),
                        TemplateSetRowItem(weightText: "5", repsText: "16")
                    ]
                )
            ]
        ),
        TemplateRowItem(
            title: "Pull Day A",
            exercises: [
                TemplateExerciseRowItem(
                    name: "Pull-Up",
                    notes: "Use controlled dead hang.",
                    restSeconds: 120,
                    sets: [
                        TemplateSetRowItem(weightText: "-", repsText: "8"),
                        TemplateSetRowItem(weightText: "-", repsText: "8"),
                        TemplateSetRowItem(weightText: "-", repsText: "6")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Barbell Row",
                    notes: "",
                    restSeconds: 120,
                    sets: [
                        TemplateSetRowItem(weightText: "55", repsText: "8"),
                        TemplateSetRowItem(weightText: "55", repsText: "8"),
                        TemplateSetRowItem(weightText: "50", repsText: "10")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Seated Cable Row",
                    notes: "",
                    restSeconds: 90,
                    sets: [
                        TemplateSetRowItem(weightText: "50", repsText: "10"),
                        TemplateSetRowItem(weightText: "50", repsText: "10"),
                        TemplateSetRowItem(weightText: "45", repsText: "12")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Face Pull",
                    notes: "Pause at peak contraction.",
                    restSeconds: 60,
                    sets: [
                        TemplateSetRowItem(weightText: "27.5", repsText: "15"),
                        TemplateSetRowItem(weightText: "27.5", repsText: "15"),
                        TemplateSetRowItem(weightText: "25", repsText: "18")
                    ]
                )
            ]
        ),
        TemplateRowItem(
            title: "Legs Day A",
            exercises: [
                TemplateExerciseRowItem(
                    name: "Back Squat",
                    notes: "Brace before every rep.",
                    restSeconds: 150,
                    sets: [
                        TemplateSetRowItem(weightText: "90", repsText: "6"),
                        TemplateSetRowItem(weightText: "90", repsText: "6"),
                        TemplateSetRowItem(weightText: "85", repsText: "8")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Romanian Deadlift",
                    notes: "",
                    restSeconds: 120,
                    sets: [
                        TemplateSetRowItem(weightText: "80", repsText: "8"),
                        TemplateSetRowItem(weightText: "80", repsText: "8"),
                        TemplateSetRowItem(weightText: "75", repsText: "10")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Leg Press",
                    notes: "",
                    restSeconds: 90,
                    sets: [
                        TemplateSetRowItem(weightText: "180", repsText: "12"),
                        TemplateSetRowItem(weightText: "180", repsText: "12"),
                        TemplateSetRowItem(weightText: "160", repsText: "15")
                    ]
                ),
                TemplateExerciseRowItem(
                    name: "Standing Calf Raise",
                    notes: "Full stretch at the bottom.",
                    restSeconds: 60,
                    sets: [
                        TemplateSetRowItem(weightText: "60", repsText: "15"),
                        TemplateSetRowItem(weightText: "60", repsText: "15"),
                        TemplateSetRowItem(weightText: "55", repsText: "18")
                    ]
                )
            ]
        )
    ]
}

struct TemplateExerciseRowItem: Identifiable {
    let id: UUID
    let name: String
    let notes: String
    let restSeconds: Int?
    let sets: [TemplateSetRowItem]

    init(
        id: UUID = UUID(),
        name: String,
        notes: String,
        restSeconds: Int?,
        sets: [TemplateSetRowItem]
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.restSeconds = restSeconds
        self.sets = sets
    }
}

struct TemplateSetRowItem: Identifiable {
    let id: UUID
    let weightText: String
    let repsText: String

    init(id: UUID = UUID(), weightText: String, repsText: String) {
        self.id = id
        self.weightText = weightText
        self.repsText = repsText
    }
}
