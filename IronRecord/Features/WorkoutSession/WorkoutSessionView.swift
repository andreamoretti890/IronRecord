import SwiftData
import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    let session: WorkoutSession

    @State private var isShowingIncompleteAlert = false
    @State private var isShowingDiscardAlert = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                ForEach(session.sortedExercises) { exercise in
                    WorkoutSessionExerciseCardView(
                        exercise: exercise,
                        onAddSet: {
                            addSet(to: exercise)
                        },
                        onDeleteExtraSet: { set in
                            deleteExtraSet(set, from: exercise)
                        },
                        onPersist: persistChanges
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemBackground))
        .navigationTitle(session.titleSnapshot)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
                    finishTapped()
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(.regularMaterial)
        }
        .alert("Finish Workout", isPresented: $isShowingIncompleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Complete every set before finishing this workout.")
        }
        .alert("Discard Workout?", isPresented: $isShowingDiscardAlert) {
            Button("Keep Workout", role: .cancel) { }
            Button("Discard", role: .destructive) {
                discardWorkout()
            }
        } message: {
            Text("This removes the workout in progress and returns to templates.")
        }
        .alert("Workout Error", isPresented: isShowingError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                persistChanges()
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button("Settings", systemImage: "slider.horizontal.3") { }
                .buttonStyle(.bordered)
                .disabled(true)
                .frame(maxWidth: .infinity)

            Button {
                isShowingDiscardAlert = true
            } label: {
                Label("Discard Workout", systemImage: "xmark.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .frame(maxWidth: .infinity)
        }
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

    private func addSet(to exercise: WorkoutSessionExercise) {
        let nextPosition = (exercise.sortedSets.last?.position ?? 0) + 1
        let set = WorkoutSessionSet(
            position: nextPosition,
            plannedWeightText: "",
            plannedRepTargetText: "",
            actualWeightText: "",
            actualRepsText: "",
            isCompleted: false,
            isExtraSet: true,
            sessionExercise: exercise
        )
        modelContext.insert(set)
        exercise.sets.append(set)
        persistChanges()
    }

    private func deleteExtraSet(_ set: WorkoutSessionSet, from exercise: WorkoutSessionExercise) {
        guard set.isExtraSet else {
            return
        }

        exercise.sets.removeAll { $0.id == set.id }
        modelContext.delete(set)

        for (index, currentSet) in exercise.sortedSets.enumerated() {
            currentSet.position = index + 1
        }

        persistChanges()
    }

    private func finishTapped() {
        guard session.allSetsCompleted else {
            isShowingIncompleteAlert = true
            return
        }

        session.finishedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func discardWorkout() {
        modelContext.delete(session)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistChanges() {
        guard modelContext.hasChanges else {
            return
        }

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutSessionPreviewContainer()
            .modelContainer(WorkoutSessionPreview.container)
    }
}

private struct WorkoutSessionPreviewContainer: View {
    @Query(
        filter: #Predicate<WorkoutSession> { session in
            session.finishedAt == nil
        },
        sort: \WorkoutSession.startedAt
    )
    private var sessions: [WorkoutSession]

    var body: some View {
        if let session = sessions.first {
            WorkoutSessionView(session: session)
        }
    }
}

private enum WorkoutSessionPreview {
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

        let descriptor = FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.createdAt)])
        let templates = try! container.mainContext.fetch(descriptor)
        if let template = templates.first {
            let session = WorkoutSession(template: template)
            container.mainContext.insert(session)
            for exercise in session.exercises {
                container.mainContext.insert(exercise)

                for set in exercise.sets {
                    container.mainContext.insert(set)
                }
            }
            try! container.mainContext.save()
        }

        return container
    }()
}
