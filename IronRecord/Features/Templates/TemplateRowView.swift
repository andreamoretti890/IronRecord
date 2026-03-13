import SwiftData
import SwiftUI

struct TemplateRowView: View {
    let template: WorkoutTemplate
    let onEditTapped: () -> Void
    let onDuplicateTapped: () -> Void
    let onDeleteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(template.name)
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
            
            Button("Start Template") {
                
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Starts \(template.name)")
        }
        .padding(14)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        if let template = TemplateRowPreview.sampleTemplate {
            TemplateRowView(
                template: template,
                onEditTapped: {},
                onDuplicateTapped: {},
                onDeleteTapped: {}
            )
            .padding()
        }
    }
    .modelContainer(TemplateRowPreview.container)
}

private enum TemplateRowPreview {
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            TemplateExerciseSet.self,
            configurations: configuration
        )
        try! SeedData.seedIfNeeded(in: container.mainContext)
        return container
    }()

    static var sampleTemplate: WorkoutTemplate? {
        let descriptor = FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.createdAt)])
        return try? container.mainContext.fetch(descriptor).first
    }
}
