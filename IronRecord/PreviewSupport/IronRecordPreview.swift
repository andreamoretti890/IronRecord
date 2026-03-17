//
//  IronRecordPreview.swift
//  IronRecord
//
//  Created by Codex on 16/03/26.
//

import Foundation
import SwiftData

enum IronRecordPreview {
    static let container: ModelContainer = {
        let container = IronRecordModelContainer.makeContainer(inMemory: true)
        try! SeedData.seedIfNeeded(in: container.mainContext)
        return container
    }()

    static var sampleTemplate: WorkoutTemplate {
        template(named: "Push A") ?? firstTemplate
    }

    static var reorderDrafts: [TemplateExerciseDraft] {
        sampleTemplate.sortedExercises.map(TemplateExerciseDraft.init(templateExercise:))
    }

    static var exerciseItems: [ExercisePickerItem] {
        exercises.map(\.pickerItem)
    }

    static func exercise(named name: String) -> Exercise? {
        exercises.first { $0.name == name }
    }

    static func template(named name: String) -> WorkoutTemplate? {
        templates.first { $0.name == name }
    }

    static func session(from template: WorkoutTemplate? = nil) -> WorkoutSession {
        let sourceTemplate = template ?? sampleTemplate

        if let existingSession = sessions.first(where: {
            $0.sourceTemplate?.persistentModelID == sourceTemplate.persistentModelID
        }) {
            return existingSession
        }

        let session = WorkoutSession.make(from: sourceTemplate)
        container.mainContext.insert(session)
        try! container.mainContext.save()
        return session
    }

    private static var exercises: [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }

    private static var templates: [WorkoutTemplate] {
        let descriptor = FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }

    private static var sessions: [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt)])
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }

    private static var firstTemplate: WorkoutTemplate {
        guard let template = templates.first else {
            fatalError("IronRecordPreview requires seeded templates.")
        }

        return template
    }
}
