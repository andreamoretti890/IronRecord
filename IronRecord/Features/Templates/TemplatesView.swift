import SwiftData
import SwiftUI

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutTemplate.createdAt) private var templates: [WorkoutTemplate]

    @State private var templatePendingDeletion: WorkoutTemplate?
    @State private var templateBeingEdited: WorkoutTemplate?
    @State private var templateBeingDuplicated: WorkoutTemplate?
    @State private var isAddTemplatePresented = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if templates.isEmpty {
                ContentUnavailableView(
                    "No Templates",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Create a template to start logging workouts.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(templates) { template in
                    TemplateRowView(
                        template: template,
                        onEditTapped: {
                            templateBeingEdited = template
                        },
                        onDuplicateTapped: {
                            templateBeingDuplicated = template
                        },
                        onDeleteTapped: {
                            templatePendingDeletion = template
                        }
                    )
                    .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Templates")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Template", systemImage: "plus") {
                    isAddTemplatePresented = true
                }
                .accessibilityHint("Creates a new template")
            }
        }
        .sheet(isPresented: $isAddTemplatePresented) {
            NavigationStack {
                AddTemplateView()
            }
            .interactiveDismissDisabled()
        }
        .sheet(item: $templateBeingEdited) { template in
            NavigationStack {
                AddTemplateView(template: template)
            }
            .interactiveDismissDisabled()
        }
        .sheet(item: $templateBeingDuplicated) { template in
            NavigationStack {
                AddTemplateView(template: template, savesAsNewTemplate: true)
            }
            .interactiveDismissDisabled()
        }
        .alert(
            "Delete Template",
            isPresented: isShowingDeleteAlert,
            presenting: templatePendingDeletion
        ) { template in
            Button("Delete", role: .destructive) {
                deleteTemplate(template)
            }
            Button("Cancel", role: .cancel) { }
        } message: { template in
            Text("Delete \(template.name)? This action cannot be undone.")
        }
        .alert("Templates Error", isPresented: isShowingError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private var isShowingDeleteAlert: Binding<Bool> {
        Binding(
            get: { templatePendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    templatePendingDeletion = nil
                }
            }
        )
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        templatePendingDeletion = nil

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
            .modelContainer(TemplatesPreview.container)
    }
}

private enum TemplatesPreview {
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
}
