import SwiftData
import SwiftUI

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutTemplate.createdAt) private var templates: [WorkoutTemplate]
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var workoutSessions: [WorkoutSession]

    @State private var templatePendingDeletion: WorkoutTemplate?
    @State private var templateBeingEdited: WorkoutTemplate?
    @State private var templateBeingDuplicated: WorkoutTemplate?
    @State private var templatePendingStart: WorkoutTemplate?
    @State private var isAddTemplatePresented = false
    @State private var presentedSession: WorkoutSession?
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let activeSession {
                resumeWorkoutCard(for: activeSession)
                    .listRowInsets(.init(top: 8, leading: 16, bottom: 10, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

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
                        },
                        onStartTapped: {
                            startTemplate(template)
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
        }
        .sheet(item: $templateBeingEdited) { template in
            NavigationStack {
                AddTemplateView(template: template)
            }
        }
        .sheet(item: $templateBeingDuplicated) { template in
            NavigationStack {
                AddTemplateView(template: template, savesAsNewTemplate: true)
            }
        }
        .sheet(item: $presentedSession) { session in
            NavigationStack {
                ActiveWorkoutView(session: session)
            }
        }
        .confirmationDialog(
            "Workout in Progress",
            isPresented: isShowingWorkoutConflict,
            presenting: activeSession
        ) { session in
            Button("Resume Workout") {
                presentedSession = session
            }

            Button("Discard and Start New", role: .destructive) {
                discardActiveSessionAndStartPendingTemplate(session)
            }

            Button("Cancel", role: .cancel) {
                templatePendingStart = nil
            }
        } message: { session in
            Text("\"\(session.templateName)\" is still in progress.")
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

    private var activeSession: WorkoutSession? {
        workoutSessions.first { $0.isInProgress }
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

    private var isShowingWorkoutConflict: Binding<Bool> {
        Binding(
            get: { templatePendingStart != nil && activeSession != nil },
            set: { isPresented in
                if !isPresented {
                    templatePendingStart = nil
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

    private func resumeWorkoutCard(for session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Workout in Progress", systemImage: "figure.strengthtraining.traditional")
                .font(.headline)

            Text(session.templateName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Resume Workout") {
                presentedSession = session
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func startTemplate(_ template: WorkoutTemplate) {
        if activeSession != nil {
            templatePendingStart = template
            presentedSession = nil
            return
        }

        createSessionAndNavigate(from: template)
    }

    private func discardActiveSessionAndStartPendingTemplate(_ activeSession: WorkoutSession) {
        let template = templatePendingStart
        templatePendingStart = nil
        modelContext.delete(activeSession)

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        if let template {
            createSessionAndNavigate(from: template)
        }
    }

    private func createSessionAndNavigate(from template: WorkoutTemplate) {
        let session = WorkoutSession.make(from: template)
        modelContext.insert(session)

        do {
            try modelContext.save()
            presentedSession = session
        } catch {
            errorMessage = error.localizedDescription
        }
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
    TemplatesPreviewHost()
        .modelContainer(TemplatesPreview.container)
}

private enum TemplatesPreview {
    static let container: ModelContainer = {
        let container = IronRecordModelContainer.makeContainer(inMemory: true)
        try! SeedData.seedIfNeeded(in: container.mainContext)
        return container
    }()
}

private struct TemplatesPreviewHost: View {
    var body: some View {
        NavigationStack {
            TemplatesView()
        }
    }
}
