import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let session: WorkoutSession

    @State private var isShowingDiscardAlert = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if session.state == .paused {
                    pausedBanner
                }

                ForEach(session.sortedExercises) { exercise in
                    WorkoutSessionExerciseCard(
                        session: session,
                        exercise: exercise,
                        isPaused: session.state == .paused,
                        onSave: saveChanges,
                        onToggleDone: { sessionSet, isCompleted in
                            toggleCompletion(
                                for: sessionSet,
                                in: exercise,
                                isCompleted: isCompleted
                            )
                        }
                    )
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Finish") {
                    finishWorkout()
                }
                .disabled(session.state == .completed)
            }

            ToolbarItem(placement: .principal) {
                WorkoutSessionToolbarHeader(
                    title: session.templateName,
                    session: session
                )
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu("Workout Actions", systemImage: "ellipsis") {
                    Button(session.state == .paused ? "Resume Workout" : "Pause Workout", systemImage: session.state == .paused ? "play.fill" : "pause.fill") {
                        togglePause()
                    }

                    Button("Reorder Exercises", systemImage: "arrow.up.arrow.down") { }
                        .disabled(true)

                    Button("Workout Settings", systemImage: "slider.horizontal.3") { }
                        .disabled(true)

                    Divider()

                    Button("Discard Workout", systemImage: "trash", role: .destructive) {
                        isShowingDiscardAlert = true
                    }
                }
            }
        }
        .alert("Discard Workout?", isPresented: $isShowingDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                discardWorkout()
            }
        } message: {
            Text("Discard this in-progress workout? Logged sets will be lost.")
        }
        .alert("Workout Error", isPresented: isShowingError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private var pausedBanner: some View {
        Label("Workout paused. Resume to keep logging sets.", systemImage: "pause.circle.fill")
            .font(.subheadline)
            .bold()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.orange)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
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

    private func toggleCompletion(
        for sessionSet: WorkoutSessionSet,
        in exercise: WorkoutSessionExercise,
        isCompleted: Bool
    ) {
        guard session.state != .paused else {
            return
        }

        let now = Date.now
        sessionSet.isCompleted = isCompleted
        sessionSet.completedAt = isCompleted ? now : nil

        if isCompleted {
            session.activateRestTimer(for: sessionSet, in: exercise, at: now)
        } else if session.activeRestIdentifier == WorkoutRestIdentifier(
            exercisePosition: exercise.position,
            setPosition: sessionSet.position
        ) {
            session.clearActiveRest()
        }

        saveChanges()
    }

    private func togglePause() {
        switch session.state {
        case .active:
            session.pause()
        case .paused:
            session.resume()
        case .completed:
            return
        }

        saveChanges()
    }

    private func finishWorkout() {
        session.finish()
        saveChanges()
        dismiss()
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

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ActiveWorkoutPreviewHost()
    .modelContainer(ActiveWorkoutPreview.container)
}

private enum ActiveWorkoutPreview {
    static let container: ModelContainer = {
        let container = IronRecordModelContainer.makeContainer(inMemory: true)
        try! SeedData.seedIfNeeded(in: container.mainContext)
        return container
    }()

    static func makeSession() -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.createdAt)])
        guard let template = try? container.mainContext.fetch(descriptor).first else {
            return nil
        }

        let session = WorkoutSession.make(from: template)
        container.mainContext.insert(session)
        try! container.mainContext.save()
        return session
    }
}

private struct ActiveWorkoutPreviewHost: View {
    @State private var isPresented = true
    @State private var session: WorkoutSession?

    var body: some View {
        NavigationStack {
            Color(.systemGroupedBackground)
                .sheet(isPresented: $isPresented) {
                    NavigationStack {
                        if let session {
                            ActiveWorkoutView(session: session)
                        }
                    }
                    .interactiveDismissDisabled()
                }
        }
        .onAppear {
            if session == nil {
                session = ActiveWorkoutPreview.makeSession()
            }
        }
    }
}
