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
        var exerciseByName = try fetchExerciseMap(from: context)
        var templateByName = try fetchTemplateMap(from: context)
        let exerciseSeedByName = Dictionary(
            uniqueKeysWithValues: starterExercises.map { ($0.name, $0) }
        )

        for exerciseSeed in starterExercises where exerciseByName[exerciseSeed.name] == nil {
            let exercise = Exercise(
                name: exerciseSeed.name,
                category: exerciseSeed.category,
                bodyPart: exerciseSeed.bodyPart,
                equipment: exerciseSeed.equipment
            )

            context.insert(exercise)
            exerciseByName[exercise.name] = exercise
        }

        for (name, exercise) in exerciseByName {
            if let seed = exerciseSeedByName[name] {
                // Keep starter exercises pinned to the canonical seed taxonomy.
                exercise.bodyPart = seed.bodyPart
                exercise.category = seed.category
            } else if exercise.bodyPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                exercise.bodyPart = "Others"
            }
        }

        for templateSeed in starterTemplates {
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
                using: exerciseByName,
                context: context
            )
        }

        if context.hasChanges {
            try context.save()
        }
    }
}

private extension SeedData {
    static func fetchExerciseMap(from context: ModelContext) throws -> [String: Exercise] {
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        return Dictionary(uniqueKeysWithValues: exercises.map { ($0.name, $0) })
    }

    static func fetchTemplateMap(from context: ModelContext) throws -> [String: WorkoutTemplate] {
        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        return Dictionary(uniqueKeysWithValues: templates.map { ($0.name, $0) })
    }

    static func seedTemplateExercisesIfMissing(
        _ templateExerciseSeeds: [TemplateExerciseSeed],
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
        using seed: TemplateExerciseSeed,
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

    struct ExerciseSeed {
        let name: String
        let category: String
        let bodyPart: String
        let equipment: String
    }

    struct TemplateExerciseSeed {
        let exerciseName: String
        let targetSets: Int
        let targetReps: String
        let restSeconds: Int
        let notes: String

        let setSeeds: [TemplateExerciseSetSeed]

        init(
            exerciseName: String,
            targetSets: Int,
            targetReps: String,
            restSeconds: Int,
            notes: String,
            setSeeds: [TemplateExerciseSetSeed]? = nil
        ) {
            self.exerciseName = exerciseName
            self.targetSets = targetSets
            self.targetReps = targetReps
            self.restSeconds = restSeconds
            self.notes = notes
            self.setSeeds = setSeeds ?? (1...targetSets).map { _ in
                TemplateExerciseSetSeed(
                    prescribedWeight: nil,
                    targetReps: Int(targetReps),
                    targetRepMin: nil,
                    targetRepMax: nil,
                    restSeconds: restSeconds,
                    type: .normal
                )
            }
        }
    }

    struct TemplateExerciseSetSeed {
        let prescribedWeight: Double?
        let targetReps: Int?
        let targetRepMin: Int?
        let targetRepMax: Int?
        let restSeconds: Int
        let type: TemplateSetType
    }

    struct TemplateSeed {
        let name: String
        let notes: String
        let exercises: [TemplateExerciseSeed]
    }

    static let starterExercises: [ExerciseSeed] = [
        ExerciseSeed(name: "Back Squat", category: "Legs", bodyPart: "Quadriceps", equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Bench Press", category: "Chest", bodyPart: "Chest", equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Overhead Press", category: "Shoulders", bodyPart: "Shoulders", equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Row", category: "Back", bodyPart: "Back", equipment: "Barbell"),
        ExerciseSeed(name: "Cable Lateral Raise", category: "Shoulders", bodyPart: "Shoulders", equipment: "Cable"),
        ExerciseSeed(name: "Chest Supported Row", category: "Back", bodyPart: "Back", equipment: "Machine"),
        ExerciseSeed(name: "Conventional Deadlift", category: "Back", bodyPart: "Back", equipment: "Barbell"),
        ExerciseSeed(name: "Dumbbell Biceps Curl", category: "Arms", bodyPart: "Biceps", equipment: "Dumbbell"),
        ExerciseSeed(name: "Face Pull", category: "Upper Back", bodyPart: "Traps", equipment: "Cable"),
        ExerciseSeed(name: "Front Squat", category: "Legs", bodyPart: "Quadriceps", equipment: "Barbell"),
        ExerciseSeed(name: "Hack Squat", category: "Legs", bodyPart: "Quadriceps", equipment: "Machine"),
        ExerciseSeed(name: "Hammer Curl", category: "Arms", bodyPart: "Forearms", equipment: "Dumbbell"),
        ExerciseSeed(name: "Hip Thrust", category: "Glutes", bodyPart: "Glutes", equipment: "Barbell"),
        ExerciseSeed(name: "Incline Dumbbell Press", category: "Chest", bodyPart: "Chest", equipment: "Dumbbell"),
        ExerciseSeed(name: "Lat Pulldown", category: "Back", bodyPart: "Back", equipment: "Machine"),
        ExerciseSeed(name: "Leg Extension", category: "Legs", bodyPart: "Quadriceps", equipment: "Machine"),
        ExerciseSeed(name: "Leg Press", category: "Legs", bodyPart: "Quadriceps", equipment: "Machine"),
        ExerciseSeed(name: "Lying Leg Curl", category: "Legs", bodyPart: "Hamstrings", equipment: "Machine"),
        ExerciseSeed(name: "Machine Chest Press", category: "Chest", bodyPart: "Chest", equipment: "Machine"),
        ExerciseSeed(name: "Pull-Up", category: "Back", bodyPart: "Back", equipment: "Bodyweight"),
        ExerciseSeed(name: "Romanian Deadlift", category: "Legs", bodyPart: "Hamstrings", equipment: "Barbell"),
        ExerciseSeed(name: "Seated Cable Row", category: "Back", bodyPart: "Back", equipment: "Cable"),
        ExerciseSeed(name: "Seated Dumbbell Shoulder Press", category: "Shoulders", bodyPart: "Shoulders", equipment: "Dumbbell"),
        ExerciseSeed(name: "Standing Calf Raise", category: "Calves", bodyPart: "Calves", equipment: "Machine"),
        ExerciseSeed(name: "Triceps Rope Pushdown", category: "Arms", bodyPart: "Triceps", equipment: "Cable")
    ]

    static let starterTemplates: [TemplateSeed] = [
        TemplateSeed(
            name: "Push A",
            notes: "Chest, shoulders, and triceps focus.",
            exercises: [
                TemplateExerciseSeed(
                    exerciseName: "Barbell Bench Press",
                    targetSets: 4,
                    targetReps: "6",
                    restSeconds: 150,
                    notes: "",
                    setSeeds: [
                        TemplateExerciseSetSeed(prescribedWeight: 40, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .warmUp),
                        TemplateExerciseSetSeed(prescribedWeight: 60, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                        TemplateExerciseSetSeed(prescribedWeight: 60, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                        TemplateExerciseSetSeed(prescribedWeight: 55, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .drop)
                    ]
                ),
                TemplateExerciseSeed(
                    exerciseName: "Incline Dumbbell Press",
                    targetSets: 3,
                    targetReps: "8",
                    restSeconds: 120,
                    notes: "",
                    setSeeds: [
                        TemplateExerciseSetSeed(prescribedWeight: 20, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .warmUp),
                        TemplateExerciseSetSeed(prescribedWeight: 26, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal),
                        TemplateExerciseSetSeed(prescribedWeight: 26, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .failure)
                    ]
                ),
                TemplateExerciseSeed(
                    exerciseName: "Seated Dumbbell Shoulder Press",
                    targetSets: 3,
                    targetReps: "8",
                    restSeconds: 120,
                    notes: "",
                    setSeeds: [
                        TemplateExerciseSetSeed(prescribedWeight: 14, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .warmUp),
                        TemplateExerciseSetSeed(prescribedWeight: 18, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal),
                        TemplateExerciseSetSeed(prescribedWeight: 18, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal)
                    ]
                ),
                TemplateExerciseSeed(
                    exerciseName: "Cable Lateral Raise",
                    targetSets: 3,
                    targetReps: "12",
                    restSeconds: 90,
                    notes: "",
                    setSeeds: [
                        TemplateExerciseSetSeed(prescribedWeight: 7.5, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .warmUp),
                        TemplateExerciseSetSeed(prescribedWeight: 10, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .normal),
                        TemplateExerciseSetSeed(prescribedWeight: 10, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .failure)
                    ]
                ),
                TemplateExerciseSeed(
                    exerciseName: "Triceps Rope Pushdown",
                    targetSets: 3,
                    targetReps: "12",
                    restSeconds: 75,
                    notes: "",
                    setSeeds: [
                        TemplateExerciseSetSeed(prescribedWeight: 18, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                        TemplateExerciseSetSeed(prescribedWeight: 27, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .normal),
                        TemplateExerciseSetSeed(prescribedWeight: 27, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .failure)
                    ]
                )
            ]
        ),
        TemplateSeed(
            name: "Pull A",
            notes: "Lats, upper back, and biceps focus.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Pull-Up", targetSets: 4, targetReps: "6", restSeconds: 150, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: nil, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: nil, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: nil, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: nil, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .failure)
                ]),
                TemplateExerciseSeed(exerciseName: "Barbell Row", targetSets: 4, targetReps: "8", restSeconds: 150, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 40, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 60, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 60, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 60, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .failure)
                ]),
                TemplateExerciseSeed(exerciseName: "Lat Pulldown", targetSets: 3, targetReps: "10", restSeconds: 120, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 32, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 45, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 45, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal)
                ]),
                TemplateExerciseSeed(exerciseName: "Face Pull", targetSets: 3, targetReps: "12", restSeconds: 90, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 14, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 20, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 20, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .failure)
                ]),
                TemplateExerciseSeed(exerciseName: "Dumbbell Biceps Curl", targetSets: 3, targetReps: "12", restSeconds: 75, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 8, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 12, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 12, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .failure)
                ])
            ]
        ),
        TemplateSeed(
            name: "Legs A",
            notes: "Quad and posterior chain emphasis.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Back Squat", targetSets: 4, targetReps: "6", restSeconds: 180, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 20, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 40, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 70, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 180, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 70, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 180, type: .normal)
                ]),
                TemplateExerciseSeed(exerciseName: "Romanian Deadlift", targetSets: 3, targetReps: "8", restSeconds: 150, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 40, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 70, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 70, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal)
                ]),
                TemplateExerciseSeed(exerciseName: "Leg Press", targetSets: 3, targetReps: "10", restSeconds: 120, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 100, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 160, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 160, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .drop)
                ]),
                TemplateExerciseSeed(exerciseName: "Lying Leg Curl", targetSets: 3, targetReps: "12", restSeconds: 90, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 18, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 27, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 27, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .failure)
                ]),
                TemplateExerciseSeed(exerciseName: "Standing Calf Raise", targetSets: 4, targetReps: "15", restSeconds: 75, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 30, targetReps: 18, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 50, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 50, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 50, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .failure)
                ])
            ]
        ),
        TemplateSeed(
            name: "Upper A",
            notes: "Balanced upper body day.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Barbell Bench Press", targetSets: 4, targetReps: "6", restSeconds: 150, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 40, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 60, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 60, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 55, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .drop)
                ]),
                TemplateExerciseSeed(exerciseName: "Seated Cable Row", targetSets: 4, targetReps: "8", restSeconds: 120, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 30, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 45, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 45, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 45, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .failure)
                ]),
                TemplateExerciseSeed(exerciseName: "Seated Dumbbell Shoulder Press", targetSets: 3, targetReps: "8", restSeconds: 120, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 14, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 18, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 18, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal)
                ]),
                TemplateExerciseSeed(exerciseName: "Cable Lateral Raise", targetSets: 3, targetReps: "12", restSeconds: 90, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 7.5, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 10, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 10, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .failure)
                ]),
                TemplateExerciseSeed(exerciseName: "Triceps Rope Pushdown", targetSets: 2, targetReps: "12", restSeconds: 75, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 20, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 28, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .normal)
                ]),
                TemplateExerciseSeed(exerciseName: "Dumbbell Biceps Curl", targetSets: 2, targetReps: "12", restSeconds: 75, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 8, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 12, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .normal)
                ])
            ]
        ),
        TemplateSeed(
            name: "Lower A",
            notes: "Lower body strength and hypertrophy.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Back Squat", targetSets: 4, targetReps: "6", restSeconds: 180, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 20, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 40, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 70, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 180, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 70, targetReps: 6, targetRepMin: nil, targetRepMax: nil, restSeconds: 180, type: .normal)
                ]),
                TemplateExerciseSeed(exerciseName: "Romanian Deadlift", targetSets: 3, targetReps: "8", restSeconds: 150, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 40, targetReps: 10, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 70, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 70, targetReps: 8, targetRepMin: nil, targetRepMax: nil, restSeconds: 150, type: .normal)
                ]),
                TemplateExerciseSeed(exerciseName: "Leg Press", targetSets: 3, targetReps: "12", restSeconds: 120, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 110, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 170, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 170, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 120, type: .drop)
                ]),
                TemplateExerciseSeed(exerciseName: "Leg Extension", targetSets: 2, targetReps: "12", restSeconds: 90, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 25, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 35, targetReps: 12, targetRepMin: nil, targetRepMax: nil, restSeconds: 90, type: .normal)
                ]),
                TemplateExerciseSeed(exerciseName: "Standing Calf Raise", targetSets: 4, targetReps: "15", restSeconds: 75, notes: "", setSeeds: [
                    TemplateExerciseSetSeed(prescribedWeight: 30, targetReps: 18, targetRepMin: nil, targetRepMax: nil, restSeconds: 60, type: .warmUp),
                    TemplateExerciseSetSeed(prescribedWeight: 50, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 50, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .normal),
                    TemplateExerciseSetSeed(prescribedWeight: 50, targetReps: 15, targetRepMin: nil, targetRepMax: nil, restSeconds: 75, type: .failure)
                ])
            ]
        )
    ]
}
