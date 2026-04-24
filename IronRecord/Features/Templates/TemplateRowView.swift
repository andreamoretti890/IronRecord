import SwiftData
import SwiftUI

struct TemplateRowView: View {
    let template: WorkoutTemplate
    let onEditTapped: () -> Void
    let onDuplicateTapped: () -> Void
    let onDeleteTapped: () -> Void
    let onStartTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
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
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onDeleteTapped()
                    }
                } label: {
                    Image(systemName: "ellipsis")
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
                onStartTapped()
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Starts \(template.name)")
        }
        .padding(14)
        .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 20))
    }
}

#Preview {
    NavigationStack {
        TemplateRowView(
            template: IronRecordPreview.sampleTemplate,
            onEditTapped: {},
            onDuplicateTapped: {},
            onDeleteTapped: {},
            onStartTapped: {}
        )
        .padding()
    }
    .modelContainer(IronRecordPreview.container)
}
