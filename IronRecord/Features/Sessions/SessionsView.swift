//
//  SessionsView.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import SwiftUI
import SwiftData

struct SessionsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]

    @State private var isStartWorkoutPresented = false
    @State private var pendingSessionToOpen: WorkoutSession?
    @State private var activeSession: WorkoutSession?
    @State private var saveErrorMessage: String?

    var body: some View {
        List {
            if inProgressSessions.isEmpty && completedSessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions Yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Tap Start Workout to log your first workout.")
                )
            } else {
                if !inProgressSessions.isEmpty {
                    Section("In Progress") {
                        ForEach(inProgressSessions) { session in
                            Button {
                                activeSession = session
                            } label: {
                                SessionRow(
                                    session: session,
                                    subtitle: "Resume workout",
                                    setCount: session.sets.count
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Reopens this active workout")
                        }
                    }
                }

                if !completedSessions.isEmpty {
                    Section("Completed") {
                        ForEach(completedSessions) { session in
                            SessionRow(
                                session: session,
                                subtitle: completionDateText(for: session),
                                setCount: loggedSetCount(for: session)
                            )
                            .accessibilityHint("Completed workout session")
                        }
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start Workout", systemImage: "plus") {
                    isStartWorkoutPresented = true
                }
                .disabled(templates.isEmpty)
                .accessibilityHint("Starts a new workout from a template")
            }
        }
        .sheet(isPresented: $isStartWorkoutPresented) {
            StartWorkoutView(
                templates: templates,
                onSelectTemplate: { template in
                    startWorkout(from: template)
                }
            )
        }
        .sheet(item: $activeSession) { session in
            ActiveWorkoutView(
                session: session,
                onFinished: {
                    activeSession = nil
                }
            )
        }
        .onChange(of: isStartWorkoutPresented) { _, isPresented in
            guard !isPresented, let pendingSessionToOpen else {
                return
            }

            activeSession = pendingSessionToOpen
            self.pendingSessionToOpen = nil
        }
        .alert(
            "Unable to Save Session",
            isPresented: isShowingSaveError,
            actions: {
                Button("OK", role: .cancel) { }
            },
            message: {
                Text(saveErrorMessage ?? "An unknown error occurred.")
            }
        )
    }

    private var inProgressSessions: [WorkoutSession] {
        sessions.filter { $0.endedAt == nil }
    }

    private var completedSessions: [WorkoutSession] {
        sessions.filter { $0.endedAt != nil }
    }

    private var isShowingSaveError: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    saveErrorMessage = nil
                }
            }
        )
    }

    private func startWorkout(from template: WorkoutTemplate) {
        guard let createdSession = createSession(from: template) else {
            return
        }

        pendingSessionToOpen = createdSession
        isStartWorkoutPresented = false
    }

    private func createSession(from template: WorkoutTemplate) -> WorkoutSession? {
        let session = WorkoutSession(
            startedAt: .now,
            endedAt: nil,
            templateName: template.name,
            notes: ""
        )

        modelContext.insert(session)

        var orderIndex = 1
        let sortedTemplateExercises = template.exercises.sorted { left, right in
            left.position < right.position
        }

        for templateExercise in sortedTemplateExercises {
            for setNumber in 1 ... templateExercise.targetSets {
                let setEntry = SetEntry(
                    orderIndex: orderIndex,
                    setNumber: setNumber,
                    exercisePosition: templateExercise.position,
                    targetRepsSnapshot: templateExercise.targetReps,
                    reps: 0,
                    weight: 0,
                    notes: "",
                    exercise: templateExercise.exercise
                )

                session.sets.append(setEntry)
                modelContext.insert(setEntry)
                orderIndex += 1
            }
        }

        do {
            try modelContext.save()
            return session
        } catch {
            saveErrorMessage = error.localizedDescription
            return nil
        }
    }

    private func loggedSetCount(for session: WorkoutSession) -> Int {
        session.sets.filter { $0.reps > 0 }.count
    }

    private func completionDateText(for session: WorkoutSession) -> String {
        guard let endedAt = session.endedAt else {
            return "In progress"
        }

        return endedAt.formatted(date: .abbreviated, time: .shortened)
    }
}

private struct SessionRow: View {
    let session: WorkoutSession
    let subtitle: String
    let setCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.templateName)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(setCount) sets")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        SessionsView()
    }
    .modelContainer(
        for: [
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            Routine.self,
            RoutineDay.self,
            WorkoutSession.self,
            SetEntry.self
        ],
        inMemory: true
    )
}
