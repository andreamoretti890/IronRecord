import SwiftData
import SwiftUI

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutTemplate.createdAt) private var templates: [WorkoutTemplate]
    @Query(
        filter: #Predicate<WorkoutSession> { session in
            session.finishedAt == nil
        },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var activeSessions: [WorkoutSession]

    @State private var templatePendingDeletion: WorkoutTemplate?
    @State private var templateBeingEdited: WorkoutTemplate?
    @State private var templateBeingDuplicated: WorkoutTemplate?
    @State private var pendingStartTemplate: WorkoutTemplate?
    @State private var activeSessionRoute: WorkoutSession?
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
                        onStartTapped: {
                            startTapped(for: template)
                        },
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
        .navigationDestination(item: $activeSessionRoute) { session in
            WorkoutSessionView(session: session)
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
        .alert(
            "Workout In Progress",
            isPresented: isShowingStartAlert,
            presenting: pendingStartTemplate
        ) { template in
            Button("Resume Workout") {
                if let session = activeSessions.first {
                    activeSessionRoute = session
                }
                pendingStartTemplate = nil
            }
            Button("Discard and Start New", role: .destructive) {
                replaceActiveWorkoutAndStart(template)
            }
            Button("Cancel", role: .cancel) {
                pendingStartTemplate = nil
            }
        } message: { _ in
            let title = activeSessions.first?.titleSnapshot ?? "your workout"
            Text("You already have \(title) in progress.")
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

    private var isShowingStartAlert: Binding<Bool> {
        Binding(
            get: { pendingStartTemplate != nil && !activeSessions.isEmpty },
            set: { isPresented in
                if !isPresented {
                    pendingStartTemplate = nil
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

    private func startTapped(for template: WorkoutTemplate) {
        if !activeSessions.isEmpty {
            pendingStartTemplate = template
            return
        }

        startWorkout(from: template)
    }

    private func replaceActiveWorkoutAndStart(_ template: WorkoutTemplate) {
        guard let activeSession = activeSessions.first else {
            startWorkout(from: template)
            return
        }

        modelContext.delete(activeSession)
        pendingStartTemplate = nil

        do {
            try modelContext.save()
            startWorkout(from: template)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startWorkout(from template: WorkoutTemplate) {
        let session = WorkoutSession(template: template)
        modelContext.insert(session)

        for exercise in session.exercises {
            modelContext.insert(exercise)

            for set in exercise.sets {
                modelContext.insert(set)
            }
        }

        do {
            try modelContext.save()
            activeSessionRoute = session
        } catch {
            modelContext.delete(session)
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
            WorkoutSession.self,
            WorkoutSessionExercise.self,
            WorkoutSessionSet.self,
            configurations: configuration
        )
        try! SeedData.seedIfNeeded(in: container.mainContext)
        return container
    }()
}
