//
//  SeedData.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import Foundation
import SwiftData

enum SeedData {
    static func seedIfNeeded(in context: ModelContext) throws {
        var exercises = try fetchExercises(from: context)
        var templateByName = try fetchTemplateMap(from: context)
        let exerciseSeedByName = Dictionary(
            uniqueKeysWithValues: StarterLibrary.exercises.map { ($0.name, $0) }
        )
        var starterExerciseByName = Dictionary(
            uniqueKeysWithValues: exercises
                .filter { $0.category != "Custom" }
                .map { ($0.name, $0) }
        )

        for exerciseSeed in StarterLibrary.exercises where starterExerciseByName[exerciseSeed.name] == nil {
            let exercise = Exercise(
                name: exerciseSeed.name,
                category: exerciseSeed.category,
                primaryBodyParts: [exerciseSeed.primaryBodyPart],
                equipment: exerciseSeed.equipment
            )

            context.insert(exercise)
            exercises.append(exercise)
            starterExerciseByName[exercise.name] = exercise
        }

        for exercise in exercises {
            guard exercise.category != "Custom" else {
                continue
            }

            if let seed = exerciseSeedByName[exercise.name] {
                // Keep starter exercises pinned to the canonical seed taxonomy.
                exercise.primaryBodyParts = [seed.primaryBodyPart]
                exercise.secondaryBodyParts = []
                exercise.category = seed.category
                exercise.equipment = seed.equipment
            } else if exercise.primaryBodyParts.isEmpty {
                exercise.primaryBodyParts = [.others]
                exercise.secondaryBodyParts = []
            }
        }

        for templateSeed in StarterLibrary.templates {
            let template: WorkoutTemplate

            if let existingTemplate = templateByName[templateSeed.name] {
                template = existingTemplate

                if template.notes.isEmpty {
                    template.notes = templateSeed.notes
                }
            } else {
                let newTemplate = WorkoutTemplate(
                    name: templateSeed.name,
                    notes: templateSeed.notes
                )
                context.insert(newTemplate)
                templateByName[newTemplate.name] = newTemplate
                template = newTemplate
            }

            seedTemplateExercisesIfMissing(
                templateSeed.exercises,
                for: template,
                using: starterExerciseByName,
                context: context
            )
        }

        if context.hasChanges {
            try context.save()
        }
    }
}

private extension SeedData {
    static func fetchExercises(from context: ModelContext) throws -> [Exercise] {
        try context.fetch(FetchDescriptor<Exercise>())
    }

    static func fetchTemplateMap(from context: ModelContext) throws -> [String: WorkoutTemplate] {
        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        return Dictionary(uniqueKeysWithValues: templates.map { ($0.name, $0) })
    }

    static func seedTemplateExercisesIfMissing(
        _ templateExerciseSeeds: [StarterLibrary.TemplateExerciseSeed],
        for template: WorkoutTemplate,
        using exerciseByName: [String: Exercise],
        context: ModelContext
    ) {
        var existingEntries: [String: TemplateExercise] = [:]

        for existingEntry in template.exercises {
            guard let exerciseName = existingEntry.exercise?.name else {
                continue
            }

            existingEntries[templateExerciseKey(position: existingEntry.position, exerciseName: exerciseName)] = existingEntry
        }

        for (index, seed) in templateExerciseSeeds.enumerated() {
            let position = index + 1
            let key = templateExerciseKey(position: position, exerciseName: seed.exerciseName)

            if let existingEntry = existingEntries[key] {
                reconcileStarterSetsIfNeeded(
                    for: existingEntry,
                    using: seed,
                    context: context
                )
                continue
            }

            guard let exercise = exerciseByName[seed.exerciseName] else {
                continue
            }

            let entry = TemplateExercise(
                position: position,
                targetSets: seed.targetSets,
                targetReps: seed.targetReps,
                restSeconds: seed.restSeconds,
                notes: seed.notes,
                exercise: exercise
            )

            entry.prescribedSets = seed.setSeeds.enumerated().map { setIndex, setSeed in
                TemplateExerciseSet(
                    position: setIndex + 1,
                    prescribedWeight: setSeed.prescribedWeight,
                    targetReps: setSeed.targetReps,
                    targetRepMin: setSeed.targetRepMin,
                    targetRepMax: setSeed.targetRepMax,
                    restSeconds: setSeed.restSeconds,
                    typeRawValue: setSeed.type.rawValue,
                    templateExercise: entry
                )
            }

            template.exercises.append(entry)
            context.insert(entry)
            for set in entry.prescribedSets {
                context.insert(set)
            }
            existingEntries[key] = entry
        }
    }

    static func reconcileStarterSetsIfNeeded(
        for entry: TemplateExercise,
        using seed: StarterLibrary.TemplateExerciseSeed,
        context: ModelContext
    ) {
        let existingSets = entry.sortedPrescribedSets
        let shouldUpgradeStarterMetadata =
            existingSets.count == seed.setSeeds.count &&
            existingSets.allSatisfy { $0.setType == .normal && $0.prescribedWeight == nil }

        if entry.targetSets == 0 {
            entry.targetSets = seed.targetSets
        }

        if entry.targetReps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            entry.targetReps = seed.targetReps
        }

        if entry.restSeconds == 0 {
            entry.restSeconds = seed.restSeconds
        }

        for (index, setSeed) in seed.setSeeds.enumerated() {
            let position = index + 1

            if let existingSet = existingSets.first(where: { $0.position == position }) {
                if existingSet.prescribedWeight == nil {
                    existingSet.prescribedWeight = setSeed.prescribedWeight
                }

                if existingSet.targetReps == nil {
                    existingSet.targetReps = setSeed.targetReps
                }

                if existingSet.targetRepMin == nil {
                    existingSet.targetRepMin = setSeed.targetRepMin
                }

                if existingSet.targetRepMax == nil {
                    existingSet.targetRepMax = setSeed.targetRepMax
                }

                if existingSet.restSeconds == 0 {
                    existingSet.restSeconds = setSeed.restSeconds
                }

                if shouldUpgradeStarterMetadata {
                    existingSet.typeRawValue = setSeed.type.rawValue
                }

                continue
            }

            let newSet = TemplateExerciseSet(
                position: position,
                prescribedWeight: setSeed.prescribedWeight,
                targetReps: setSeed.targetReps,
                targetRepMin: setSeed.targetRepMin,
                targetRepMax: setSeed.targetRepMax,
                restSeconds: setSeed.restSeconds,
                typeRawValue: setSeed.type.rawValue,
                templateExercise: entry
            )

            entry.prescribedSets.append(newSet)
            context.insert(newSet)
        }
    }

    static func templateExerciseKey(position: Int, exerciseName: String) -> String {
        "\(position)|\(exerciseName)"
    }
}
