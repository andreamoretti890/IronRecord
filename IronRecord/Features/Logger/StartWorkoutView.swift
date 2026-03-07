//
//  StartWorkoutView.swift
//  IronRecord
//
//  Created by Codex on 17/02/26.
//

import SwiftUI

struct StartWorkoutView: View {
    let templates: [WorkoutTemplate]
    let onSelectTemplate: (WorkoutTemplate) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates Available",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("Create or seed templates before starting a workout.")
                    )
                } else {
                    ForEach(templates) { template in
                        Button {
                            onSelectTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.headline)
                                Text("\(template.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityHint("Starts a new workout from this template")
                        }
                    }
                }
            }
            .navigationTitle("Start Workout")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
