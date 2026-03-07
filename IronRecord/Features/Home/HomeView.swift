//
//  HomeView.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var exercises: [Exercise]
    @Query private var templates: [WorkoutTemplate]
    @Query private var routines: [Routine]
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]

    private var activeRoutine: Routine? {
        routines
            .filter(\.isActive)
            .sorted { $0.name < $1.name }
            .first
    }

    private var completedSessions: [WorkoutSession] {
        sessions.filter { $0.endedAt != nil }
    }

    private var inProgressCount: Int {
        sessions.filter { $0.endedAt == nil }.count
    }

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Exercises", value: "\(exercises.count)")
                LabeledContent("Templates", value: "\(templates.count)")
                LabeledContent("Routines", value: "\(routines.count)")
                LabeledContent("Sessions", value: "\(completedSessions.count)")

                if inProgressCount > 0 {
                    LabeledContent("In Progress", value: "\(inProgressCount)")
                }
            }

            Section("Current Routine") {
                if let activeRoutine {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activeRoutine.name)
                            .font(.headline)
                        Text(activeRoutine.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Active training split")

                    ForEach(sortedDays(for: activeRoutine)) { day in
                        LabeledContent(day.weekdayName, value: day.template?.name ?? "Unassigned")
                    }
                } else {
                    ContentUnavailableView(
                        "No Active Routine",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Mark a routine as active to see your weekly schedule here.")
                    )
                }
            }

            Section("Recent Sessions") {
                if completedSessions.isEmpty {
                    Text("No sessions logged yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(completedSessions.prefix(3))) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.templateName)
                                .font(.headline)
                            Text(session.endedAt ?? session.startedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityHint("Recent workout session")
                    }
                }
            }
        }
        .navigationTitle("IronRecord")
    }

    private func sortedDays(for routine: Routine) -> [RoutineDay] {
        routine.days.sorted { left, right in
            if left.position == right.position {
                return left.weekday < right.weekday
            }

            return left.position < right.position
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
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
