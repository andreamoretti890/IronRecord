//
//  WorkoutSession.swift
//  IronRecord
//
//  Created by Codex on 11/03/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession: Identifiable {
    @Attribute(.unique) var id: UUID
    var titleSnapshot: String
    var startedAt: Date
    var finishedAt: Date?

    var sourceTemplate: WorkoutTemplate?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSessionExercise.session)
    var exercises: [WorkoutSessionExercise]

    init(
        id: UUID = UUID(),
        titleSnapshot: String,
        startedAt: Date = .now,
        finishedAt: Date? = nil,
        sourceTemplate: WorkoutTemplate? = nil
    ) {
        self.id = id
        self.titleSnapshot = titleSnapshot
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.sourceTemplate = sourceTemplate
        exercises = []
    }

    convenience init(template: WorkoutTemplate, startedAt: Date = .now) {
        self.init(
            titleSnapshot: template.name,
            startedAt: startedAt,
            sourceTemplate: template
        )

        exercises = template.sortedExercises.map { templateExercise in
            let sessionExercise = WorkoutSessionExercise(
                position: templateExercise.position,
                nameSnapshot: templateExercise.displayName,
                notes: templateExercise.notes,
                restSeconds: templateExercise.restSeconds,
                session: self,
                templateExercise: templateExercise,
                exercise: templateExercise.exercise
            )

            let prescribedSets = templateExercise.sortedPrescribedSets
            if prescribedSets.isEmpty {
                sessionExercise.sets = (1...max(templateExercise.targetSets, 1)).map { position in
                    WorkoutSessionSet(
                        position: position,
                        plannedWeightText: "",
                        plannedRepTargetText: templateExercise.displayRepTargetText,
                        actualWeightText: "",
                        actualRepsText: "",
                        isCompleted: false,
                        isExtraSet: false,
                        sessionExercise: sessionExercise
                    )
                }
            } else {
                sessionExercise.sets = prescribedSets.map { prescribedSet in
                    WorkoutSessionSet(
                        position: prescribedSet.position,
                        plannedWeightText: prescribedSet.displayWeightText,
                        plannedRepTargetText: prescribedSet.displayRepText.isEmpty
                            ? templateExercise.displayRepTargetText
                            : prescribedSet.displayRepText,
                        actualWeightText: "",
                        actualRepsText: "",
                        isCompleted: false,
                        isExtraSet: false,
                        sessionExercise: sessionExercise
                    )
                }
            }

            return sessionExercise
        }
    }

    var isFinished: Bool {
        finishedAt != nil
    }

    var sortedExercises: [WorkoutSessionExercise] {
        exercises.sorted { left, right in
            left.position < right.position
        }
    }

    var allSetsCompleted: Bool {
        sortedExercises.allSatisfy { exercise in
            exercise.sortedSets.allSatisfy(\.isCompleted)
        }
    }
}

@Model
final class WorkoutSessionExercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var position: Int
    var nameSnapshot: String
    var notes: String
    var restSeconds: Int

    var session: WorkoutSession?
    var templateExercise: TemplateExercise?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSessionSet.sessionExercise)
    var sets: [WorkoutSessionSet]

    init(
        id: UUID = UUID(),
        position: Int,
        nameSnapshot: String,
        notes: String,
        restSeconds: Int,
        session: WorkoutSession? = nil,
        templateExercise: TemplateExercise? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.position = position
        self.nameSnapshot = nameSnapshot
        self.notes = notes
        self.restSeconds = restSeconds
        self.session = session
        self.templateExercise = templateExercise
        self.exercise = exercise
        sets = []
    }

    var sortedSets: [WorkoutSessionSet] {
        sets.sorted { left, right in
            left.position < right.position
        }
    }
}

@Model
final class WorkoutSessionSet: Identifiable {
    @Attribute(.unique) var id: UUID
    var position: Int
    var plannedWeightText: String
    var plannedRepTargetText: String
    var actualWeightText: String
    var actualRepsText: String
    var isCompleted: Bool
    var isExtraSet: Bool

    var sessionExercise: WorkoutSessionExercise?

    init(
        id: UUID = UUID(),
        position: Int,
        plannedWeightText: String,
        plannedRepTargetText: String,
        actualWeightText: String,
        actualRepsText: String,
        isCompleted: Bool,
        isExtraSet: Bool,
        sessionExercise: WorkoutSessionExercise? = nil
    ) {
        self.id = id
        self.position = position
        self.plannedWeightText = plannedWeightText
        self.plannedRepTargetText = plannedRepTargetText
        self.actualWeightText = actualWeightText
        self.actualRepsText = actualRepsText
        self.isCompleted = isCompleted
        self.isExtraSet = isExtraSet
        self.sessionExercise = sessionExercise
    }
}

extension TemplateExerciseSet {
    var displayWeightText: String {
        guard let prescribedWeight else {
            return ""
        }

        if prescribedWeight == floor(prescribedWeight) {
            return String(Int(prescribedWeight))
        }

        return prescribedWeight.formatted(
            .number.precision(.fractionLength(0 ... 2))
        )
    }
}
