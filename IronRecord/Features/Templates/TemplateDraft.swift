//
//  TemplateDraft.swift
//  IronRecord
//
//  Created by Codex on 17/02/26.
//

import Foundation

struct TemplateDraft: Equatable {
    var name: String
    var notes: String
    var exercises: [TemplateExerciseDraft]

    static func new(defaultExerciseName: String?) -> TemplateDraft {
        let exercises: [TemplateExerciseDraft]

        if let defaultExerciseName {
            exercises = [TemplateExerciseDraft(exerciseName: defaultExerciseName)]
        } else {
            exercises = []
        }

        return TemplateDraft(name: "", notes: "", exercises: exercises)
    }

    init(name: String, notes: String, exercises: [TemplateExerciseDraft]) {
        self.name = name
        self.notes = notes
        self.exercises = exercises
    }

    init(template: WorkoutTemplate) {
        name = template.name
        notes = template.notes
        exercises = template.exercises
            .sorted(by: { left, right in
                left.position < right.position
            })
            .map { entry in
                TemplateExerciseDraft(
                    exerciseName: entry.exercise?.name ?? "",
                    targetSets: entry.targetSets,
                    targetReps: entry.targetReps,
                    restSeconds: entry.restSeconds,
                    notes: entry.notes
                )
            }
    }
}

struct TemplateExerciseDraft: Equatable, Identifiable {
    let id: UUID
    var exerciseName: String
    var targetSets: Int
    var targetReps: String
    var restSeconds: Int
    var notes: String

    init(
        id: UUID = UUID(),
        exerciseName: String,
        targetSets: Int = 3,
        targetReps: String = "8-12",
        restSeconds: Int = 90,
        notes: String = ""
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.notes = notes
    }
}
