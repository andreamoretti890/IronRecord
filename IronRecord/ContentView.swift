//
//  ContentView.swift
//  IronRecord
//
//  Created by Andrea Moretti on 16/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: AppTab = .home
    @State private var hasSeeded = false
    @State private var seedErrorMessage: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
            }
            .tag(AppTab.home)

            NavigationStack {
                TemplatesView()
            }
            .tabItem {
                Label(AppTab.templates.title, systemImage: AppTab.templates.systemImage)
            }
            .tag(AppTab.templates)

            NavigationStack {
                RoutinesView()
            }
            .tabItem {
                Label(AppTab.routines.title, systemImage: AppTab.routines.systemImage)
            }
            .tag(AppTab.routines)

            NavigationStack {
                SessionsView()
            }
            .tabItem {
                Label(AppTab.sessions.title, systemImage: AppTab.sessions.systemImage)
            }
            .tag(AppTab.sessions)
        }
        .task {
            seedIfNeeded()
        }
        .alert(
            "Seed Data Error",
            isPresented: isShowingSeedError,
            actions: {
                Button("OK", role: .cancel) { }
            },
            message: {
                Text(seedErrorMessage ?? "An unknown error occurred.")
            }
        )
    }

    private var isShowingSeedError: Binding<Bool> {
        Binding(
            get: { seedErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    seedErrorMessage = nil
                }
            }
        )
    }

    private func seedIfNeeded() {
        guard !hasSeeded else {
            return
        }

        hasSeeded = true

        do {
            try SeedData.seedIfNeeded(in: modelContext)
        } catch {
            seedErrorMessage = error.localizedDescription
        }
    }
}

private enum AppTab: Hashable {
    case home
    case templates
    case routines
    case sessions

    var title: String {
        switch self {
        case .home:
            "Home"
        case .templates:
            "Templates"
        case .routines:
            "Routines"
        case .sessions:
            "Sessions"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .templates:
            "list.bullet.rectangle"
        case .routines:
            "calendar"
        case .sessions:
            "chart.bar.xaxis"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                Exercise.self,
                WorkoutTemplate.self,
                TemplateExercise.self,
                Routine.self,
                RoutineDay.self,
                WorkoutSession.self,
                SetEntry.self
            ],
            inMemory: true
        )
}
