//
//  Routine.swift
//  IronRecord
//
//  Created by Codex on 16/02/26.
//

import Foundation
import SwiftData

@Model
final class Routine {
    @Attribute(.unique) var name: String
    var notes: String
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineDay.routine)
    var days: [RoutineDay]

    init(
        name: String,
        notes: String = "",
        isActive: Bool = false,
        createdAt: Date = .now
    ) {
        self.name = name
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        days = []
    }
}

@Model
final class RoutineDay {
    var weekday: Int
    var position: Int
    var notes: String

    var routine: Routine?
    var template: WorkoutTemplate?

    init(
        weekday: Int,
        position: Int,
        notes: String = "",
        routine: Routine? = nil,
        template: WorkoutTemplate? = nil
    ) {
        self.weekday = weekday
        self.position = position
        self.notes = notes
        self.routine = routine
        self.template = template
    }
}

extension RoutineDay {
    var weekdayName: String {
        let symbols = Calendar.current.weekdaySymbols
        let clampedIndex = min(max(weekday, 1), symbols.count) - 1
        return symbols[clampedIndex]
    }
}
