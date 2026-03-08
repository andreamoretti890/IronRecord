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
    @Attribute(.unique) var name: String
    var category: String
    var bodyPart: String
    var equipment: String
    var notes: String
    var createdAt: Date

    @Relationship(inverse: \TemplateExercise.exercise)
    var templateEntries: [TemplateExercise]

    init(
        name: String,
        category: String,
        bodyPart: String = "Others",
        equipment: String,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.category = category
        self.bodyPart = bodyPart
        self.equipment = equipment
        self.notes = notes
        self.createdAt = createdAt
        templateEntries = []
    }
}
