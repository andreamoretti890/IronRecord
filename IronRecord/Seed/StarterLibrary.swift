//
//  StarterLibrary.swift
//  IronRecord
//
//  Created by Codex on 16/03/26.
//

import Foundation

enum StarterLibrary {
    struct ExerciseSeed {
        let name: String
        let category: String
        let primaryBodyPart: ExerciseBodyPart
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

    static let exercises: [ExerciseSeed] = [
        ExerciseSeed(name: "Back Squat", category: "Legs", primaryBodyPart: .quads, equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Bench Press", category: "Chest", primaryBodyPart: .chest, equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Overhead Press", category: "Shoulders", primaryBodyPart: .shoulders, equipment: "Barbell"),
        ExerciseSeed(name: "Barbell Row", category: "Back", primaryBodyPart: .middleBack, equipment: "Barbell"),
        ExerciseSeed(name: "Cable Lateral Raise", category: "Shoulders", primaryBodyPart: .shoulders, equipment: "Cable (Single)"),
        ExerciseSeed(name: "Chest Supported Row", category: "Back", primaryBodyPart: .middleBack, equipment: "Machine"),
        ExerciseSeed(name: "Conventional Deadlift", category: "Back", primaryBodyPart: .lowerBack, equipment: "Barbell"),
        ExerciseSeed(name: "Dumbbell Biceps Curl", category: "Arms", primaryBodyPart: .biceps, equipment: "Dumbbell (Single)"),
        ExerciseSeed(name: "Face Pull", category: "Upper Back", primaryBodyPart: .traps, equipment: "Rope"),
        ExerciseSeed(name: "Front Squat", category: "Legs", primaryBodyPart: .quads, equipment: "Barbell"),
        ExerciseSeed(name: "Hack Squat", category: "Legs", primaryBodyPart: .quads, equipment: "Machine"),
        ExerciseSeed(name: "Hammer Curl", category: "Arms", primaryBodyPart: .forearms, equipment: "Dumbbell (Single)"),
        ExerciseSeed(name: "Hip Thrust", category: "Glutes", primaryBodyPart: .glutes, equipment: "Barbell"),
        ExerciseSeed(name: "Incline Dumbbell Press", category: "Chest", primaryBodyPart: .chest, equipment: "Dumbbell (Double)"),
        ExerciseSeed(name: "Lat Pulldown", category: "Back", primaryBodyPart: .lats, equipment: "Machine"),
        ExerciseSeed(name: "Leg Extension", category: "Legs", primaryBodyPart: .quads, equipment: "Machine"),
        ExerciseSeed(name: "Leg Press", category: "Legs", primaryBodyPart: .quads, equipment: "Machine"),
        ExerciseSeed(name: "Lying Leg Curl", category: "Legs", primaryBodyPart: .hamstrings, equipment: "Machine"),
        ExerciseSeed(name: "Machine Chest Press", category: "Chest", primaryBodyPart: .chest, equipment: "Machine"),
        ExerciseSeed(name: "Pull-Up", category: "Back", primaryBodyPart: .lats, equipment: "Bodyweight"),
        ExerciseSeed(name: "Romanian Deadlift", category: "Legs", primaryBodyPart: .hamstrings, equipment: "Barbell"),
        ExerciseSeed(name: "Seated Cable Row", category: "Back", primaryBodyPart: .middleBack, equipment: "Cable (Double)"),
        ExerciseSeed(name: "Seated Dumbbell Shoulder Press", category: "Shoulders", primaryBodyPart: .shoulders, equipment: "Dumbbell (Double)"),
        ExerciseSeed(name: "Standing Calf Raise", category: "Calves", primaryBodyPart: .calves, equipment: "Machine"),
        ExerciseSeed(name: "Triceps Rope Pushdown", category: "Arms", primaryBodyPart: .triceps, equipment: "Rope")
    ]

    static let templates: [TemplateSeed] = [
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
