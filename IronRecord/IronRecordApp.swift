//
//  IronRecordApp.swift
//  IronRecord
//
//  Created by Andrea Moretti on 16/02/26.
//

import SwiftUI
import SwiftData

@main
struct IronRecordApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [
                Exercise.self,
                WorkoutTemplate.self,
                TemplateExercise.self,
                TemplateExerciseSet.self
            ]
        )
    }
}
