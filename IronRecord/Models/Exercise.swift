//
//  Exercise.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var category: String
    var primaryBodyParts: [ExerciseBodyPart]
    var secondaryBodyParts: [ExerciseBodyPart]
    var equipment: String
    var notes: String
    var createdAt: Date

    @Relationship(inverse: \TemplateExercise.exercise)
    var templateEntries: [TemplateExercise]

    init(
        name: String,
        category: String,
        primaryBodyParts: [ExerciseBodyPart],
        secondaryBodyParts: [ExerciseBodyPart] = [],
        equipment: String,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.category = category
        self.primaryBodyParts = primaryBodyParts
        self.secondaryBodyParts = secondaryBodyParts
        self.equipment = equipment
        self.notes = notes
        self.createdAt = createdAt
        templateEntries = []
    }
}
