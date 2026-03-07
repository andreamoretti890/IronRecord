//
//  RoutinesView.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Query(sort: \Routine.name) private var routines: [Routine]

    var body: some View {
        List {
            if routines.isEmpty {
                ContentUnavailableView(
                    "No Routines",
                    systemImage: "calendar",
                    description: Text("Routines are added when the app seeds starter data.")
                )
            } else {
                ForEach(routines) { routine in
                    Section {
                        if !routine.notes.isEmpty {
                            Text(routine.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(sortedDays(for: routine)) { day in
                            LabeledContent(day.weekdayName, value: day.template?.name ?? "Unassigned")
                        }
                    } header: {
                        HStack {
                            Text(routine.name)

                            if routine.isActive {
                                Text("ACTIVE")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .navigationTitle("Routines")
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
        RoutinesView()
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
