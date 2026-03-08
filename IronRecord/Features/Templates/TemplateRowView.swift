import SwiftUI

struct TemplateRowView: View {
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

struct TemplateRowItem: Identifiable {
    let id = UUID()
    let title: String
    let exercises: [String]

    var exercisePreview: String {
        exercises.joined(separator: ", ")
    }

    static let mock: [TemplateRowItem] = [
        TemplateRowItem(
            title: "Push Day A",
            exercises: [
                "Barbell Bench Press",
                "Incline Dumbbell Press",
                "Seated Shoulder Press",
                "Cable Lateral Raise"
            ]
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
