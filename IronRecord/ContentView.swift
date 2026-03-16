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

    @State private var hasSeeded = false
    @State private var seedErrorMessage: String?

    var body: some View {
        NavigationStack {
            TemplatesView()
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

#Preview {
    ContentView()
        .modelContainer(IronRecordModelContainer.makeContainer(inMemory: true))
}
