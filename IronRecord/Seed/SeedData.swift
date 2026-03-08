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

        for exerciseSeed in starterExercises where exerciseByName[exerciseSeed.name] == nil {
            let exercise = Exercise(
                name: exerciseSeed.name,
                category: exerciseSeed.category,
                equipment: exerciseSeed.equipment
            )

            context.insert(exercise)
            exerciseByName[exercise.name] = exercise
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
        var existingKeys: Set<String> = []

        for existingEntry in template.exercises {
            guard let exerciseName = existingEntry.exercise?.name else {
                continue
            }

            existingKeys.insert(templateExerciseKey(position: existingEntry.position, exerciseName: exerciseName))
        }

        for (index, seed) in templateExerciseSeeds.enumerated() {
            let position = index + 1
            let key = templateExerciseKey(position: position, exerciseName: seed.exerciseName)

            guard !existingKeys.contains(key) else {
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

            template.exercises.append(entry)
            context.insert(entry)
            existingKeys.insert(key)
        }
    }

    static func templateExerciseKey(position: Int, exerciseName: String) -> String {
        "\(position)|\(exerciseName)"
    }

    struct ExerciseSeed {
        let name: String
        let category: String
        let equipment: String
    }

    struct TemplateExerciseSeed {
        let exerciseName: String
        let targetSets: Int
        let targetReps: String
        let restSeconds: Int
        let notes: String
    }

    struct TemplateSeed {
        let name: String
        let notes: String
        let exercises: [TemplateExerciseSeed]
    }

    static let starterExercises: [ExerciseSeed] = [
        ExerciseSeed(name: "Back Squat", category: "Legs", equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Bench Press", category: "Chest", equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Overhead Press", category: "Shoulders", equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Row", category: "Back", equipment: "Barbell"),
        ExerciseSeed(name: "Cable Lateral Raise", category: "Shoulders", equipment: "Cable"),
        ExerciseSeed(name: "Chest Supported Row", category: "Back", equipment: "Machine"),
        ExerciseSeed(name: "Conventional Deadlift", category: "Back", equipment: "Barbell"),
        ExerciseSeed(name: "Dumbbell Biceps Curl", category: "Arms", equipment: "Dumbbell"),
        ExerciseSeed(name: "Face Pull", category: "Upper Back", equipment: "Cable"),
        ExerciseSeed(name: "Front Squat", category: "Legs", equipment: "Barbell"),
        ExerciseSeed(name: "Hack Squat", category: "Legs", equipment: "Machine"),
        ExerciseSeed(name: "Hammer Curl", category: "Arms", equipment: "Dumbbell"),
        ExerciseSeed(name: "Hip Thrust", category: "Glutes", equipment: "Barbell"),
        ExerciseSeed(name: "Incline Dumbbell Press", category: "Chest", equipment: "Dumbbell"),
        ExerciseSeed(name: "Lat Pulldown", category: "Back", equipment: "Machine"),
        ExerciseSeed(name: "Leg Extension", category: "Legs", equipment: "Machine"),
        ExerciseSeed(name: "Leg Press", category: "Legs", equipment: "Machine"),
        ExerciseSeed(name: "Lying Leg Curl", category: "Legs", equipment: "Machine"),
        ExerciseSeed(name: "Machine Chest Press", category: "Chest", equipment: "Machine"),
        ExerciseSeed(name: "Pull-Up", category: "Back", equipment: "Bodyweight"),
        ExerciseSeed(name: "Romanian Deadlift", category: "Legs", equipment: "Barbell"),
        ExerciseSeed(name: "Seated Cable Row", category: "Back", equipment: "Cable"),
        ExerciseSeed(name: "Seated Dumbbell Shoulder Press", category: "Shoulders", equipment: "Dumbbell"),
        ExerciseSeed(name: "Standing Calf Raise", category: "Calves", equipment: "Machine"),
        ExerciseSeed(name: "Triceps Rope Pushdown", category: "Arms", equipment: "Cable")
    ]

    static let starterTemplates: [TemplateSeed] = [
        TemplateSeed(
            name: "Push A",
            notes: "Chest, shoulders, and triceps focus.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Barbell Bench Press", targetSets: 4, targetReps: "5-8", restSeconds: 150, notes: ""),
                TemplateExerciseSeed(exerciseName: "Incline Dumbbell Press", targetSets: 3, targetReps: "8-12", restSeconds: 120, notes: ""),
                TemplateExerciseSeed(exerciseName: "Seated Dumbbell Shoulder Press", targetSets: 3, targetReps: "8-10", restSeconds: 120, notes: ""),
                TemplateExerciseSeed(exerciseName: "Cable Lateral Raise", targetSets: 3, targetReps: "12-15", restSeconds: 90, notes: ""),
                TemplateExerciseSeed(exerciseName: "Triceps Rope Pushdown", targetSets: 3, targetReps: "10-15", restSeconds: 75, notes: "")
            ]
        ),
        TemplateSeed(
            name: "Pull A",
            notes: "Lats, upper back, and biceps focus.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Pull-Up", targetSets: 4, targetReps: "5-8", restSeconds: 150, notes: ""),
                TemplateExerciseSeed(exerciseName: "Barbell Row", targetSets: 4, targetReps: "6-10", restSeconds: 150, notes: ""),
                TemplateExerciseSeed(exerciseName: "Lat Pulldown", targetSets: 3, targetReps: "10-12", restSeconds: 120, notes: ""),
                TemplateExerciseSeed(exerciseName: "Face Pull", targetSets: 3, targetReps: "12-15", restSeconds: 90, notes: ""),
                TemplateExerciseSeed(exerciseName: "Dumbbell Biceps Curl", targetSets: 3, targetReps: "10-15", restSeconds: 75, notes: "")
            ]
        ),
        TemplateSeed(
            name: "Legs A",
            notes: "Quad and posterior chain emphasis.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Back Squat", targetSets: 4, targetReps: "5-8", restSeconds: 180, notes: ""),
                TemplateExerciseSeed(exerciseName: "Romanian Deadlift", targetSets: 3, targetReps: "6-10", restSeconds: 150, notes: ""),
                TemplateExerciseSeed(exerciseName: "Leg Press", targetSets: 3, targetReps: "10-12", restSeconds: 120, notes: ""),
                TemplateExerciseSeed(exerciseName: "Lying Leg Curl", targetSets: 3, targetReps: "10-15", restSeconds: 90, notes: ""),
                TemplateExerciseSeed(exerciseName: "Standing Calf Raise", targetSets: 4, targetReps: "12-20", restSeconds: 75, notes: "")
            ]
        ),
        TemplateSeed(
            name: "Upper A",
            notes: "Balanced upper body day.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Barbell Bench Press", targetSets: 4, targetReps: "5-8", restSeconds: 150, notes: ""),
                TemplateExerciseSeed(exerciseName: "Seated Cable Row", targetSets: 4, targetReps: "8-12", restSeconds: 120, notes: ""),
                TemplateExerciseSeed(exerciseName: "Seated Dumbbell Shoulder Press", targetSets: 3, targetReps: "8-10", restSeconds: 120, notes: ""),
                TemplateExerciseSeed(exerciseName: "Cable Lateral Raise", targetSets: 3, targetReps: "12-15", restSeconds: 90, notes: ""),
                TemplateExerciseSeed(exerciseName: "Triceps Rope Pushdown", targetSets: 2, targetReps: "10-15", restSeconds: 75, notes: ""),
                TemplateExerciseSeed(exerciseName: "Dumbbell Biceps Curl", targetSets: 2, targetReps: "10-15", restSeconds: 75, notes: "")
            ]
        ),
        TemplateSeed(
            name: "Lower A",
            notes: "Lower body strength and hypertrophy.",
            exercises: [
                TemplateExerciseSeed(exerciseName: "Back Squat", targetSets: 4, targetReps: "5-8", restSeconds: 180, notes: ""),
                TemplateExerciseSeed(exerciseName: "Romanian Deadlift", targetSets: 3, targetReps: "6-10", restSeconds: 150, notes: ""),
                TemplateExerciseSeed(exerciseName: "Leg Press", targetSets: 3, targetReps: "10-15", restSeconds: 120, notes: ""),
                TemplateExerciseSeed(exerciseName: "Leg Extension", targetSets: 2, targetReps: "12-15", restSeconds: 90, notes: ""),
                TemplateExerciseSeed(exerciseName: "Standing Calf Raise", targetSets: 4, targetReps: "12-20", restSeconds: 75, notes: "")
            ]
        )
    ]
}
