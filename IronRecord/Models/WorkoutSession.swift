//
//  WorkoutSession.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var startedAt: Date
    var endedAt: Date?
    var templateName: String
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.session)
    var sets: [SetEntry]

    init(
        startedAt: Date = .now,
        endedAt: Date? = nil,
        templateName: String,
        notes: String = ""
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.templateName = templateName
        self.notes = notes
        sets = []
    }
}

@Model
final class SetEntry {
    var orderIndex: Int
    var setNumber: Int
    var exercisePosition: Int
    var targetRepsSnapshot: String
    var reps: Int
    var weight: Double
    var rpe: Double?
    var isWarmup: Bool
    var notes: String

    var session: WorkoutSession?
    var exercise: Exercise?

    init(
        orderIndex: Int,
        setNumber: Int = 1,
        exercisePosition: Int = 1,
        targetRepsSnapshot: String = "",
        reps: Int,
        weight: Double,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        notes: String = "",
        session: WorkoutSession? = nil,
        exercise: Exercise? = nil
    ) {
        self.orderIndex = orderIndex
        self.setNumber = setNumber
        self.exercisePosition = exercisePosition
        self.targetRepsSnapshot = targetRepsSnapshot
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.notes = notes
        self.session = session
        self.exercise = exercise
    }
}
