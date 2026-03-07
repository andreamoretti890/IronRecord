//
//  WorkoutTemplate.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    @Attribute(.unique) var name: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    @Relationship(inverse: \RoutineDay.template)
    var routineDays: [RoutineDay]

    init(
        name: String,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        exercises = []
        routineDays = []
    }
}

@Model
final class TemplateExercise {
    var position: Int
    var targetSets: Int
    var targetReps: String
    var restSeconds: Int
    var notes: String

    var template: WorkoutTemplate?
    var exercise: Exercise?

    init(
        position: Int,
        targetSets: Int,
        targetReps: String,
        restSeconds: Int,
        notes: String = "",
        template: WorkoutTemplate? = nil,
        exercise: Exercise? = nil
    ) {
        self.position = position
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.notes = notes
        self.template = template
        self.exercise = exercise
    }
}
