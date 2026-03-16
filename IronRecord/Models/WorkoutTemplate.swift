//
//  WorkoutTemplate.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutTemplate: Identifiable {
    @Attribute(.unique) var name: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    init(
        name: String,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        exercises = []
    }
}

@Model
final class TemplateExercise: Identifiable {
    var position: Int
    var targetSets: Int
    var targetReps: String
    var restSeconds: Int
    var notes: String

    var template: WorkoutTemplate?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \TemplateExerciseSet.templateExercise)
    var prescribedSets: [TemplateExerciseSet]

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
        prescribedSets = []
    }
}

@Model
final class TemplateExerciseSet: Identifiable {
    var position: Int
    var prescribedWeight: Double?
    var targetReps: Int?
    var targetRepMin: Int?
    var targetRepMax: Int?
    var restSeconds: Int
    var typeRawValue: String

    var templateExercise: TemplateExercise?

    init(
        position: Int,
        prescribedWeight: Double? = nil,
        targetReps: Int? = nil,
        targetRepMin: Int? = nil,
        targetRepMax: Int? = nil,
        restSeconds: Int = 0,
        typeRawValue: String = TemplateSetType.normal.rawValue,
        templateExercise: TemplateExercise? = nil
    ) {
        self.position = position
        self.prescribedWeight = prescribedWeight
        self.targetReps = targetReps
        self.targetRepMin = targetRepMin
        self.targetRepMax = targetRepMax
        self.restSeconds = restSeconds
        self.typeRawValue = typeRawValue
        self.templateExercise = templateExercise
    }
}

enum TemplateSetType: String, CaseIterable, Codable {
    case normal
    case warmUp = "warm_up"
    case failure
    case drop
}

extension TemplateExercise {
    var displayName: String {
        exercise?.name ?? "Exercise"
    }

    var sortedPrescribedSets: [TemplateExerciseSet] {
        prescribedSets.sorted { left, right in
            left.position < right.position
        }
    }

    var displayRepTargetText: String {
        let setTargets = sortedPrescribedSets
            .map(\.displayRepText)
            .filter { !$0.isEmpty }

        guard !setTargets.isEmpty else {
            let trimmedTarget = targetReps.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedTarget.isEmpty ? "No rep target" : trimmedTarget
        }

        let uniqueTargets = Set(setTargets)
        if uniqueTargets.count == 1, let onlyTarget = uniqueTargets.first {
            return onlyTarget
        }

        return "Variable"
    }
}

extension WorkoutTemplate {
    var sortedExercises: [TemplateExercise] {
        exercises.sorted { left, right in
            left.position < right.position
        }
    }

    var exercisePreview: String {
        let names = sortedExercises.map(\.displayName)
        guard !names.isEmpty else {
            return "No exercises"
        }

        return names.joined(separator: ", ")
    }
}

extension TemplateExerciseSet {
    var setType: TemplateSetType {
        get { TemplateSetType(rawValue: typeRawValue) ?? .normal }
        set { typeRawValue = newValue.rawValue }
    }

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

    var displayRepText: String {
        if let targetRepMin, let targetRepMax {
            return "\(targetRepMin)-\(targetRepMax)"
        }

        if let targetReps {
            return "\(targetReps)"
        }

        return ""
    }

    var effectiveRestSeconds: Int {
        if restSeconds > 0 {
            return restSeconds
        }

        return templateExercise?.restSeconds ?? 0
    }
}
