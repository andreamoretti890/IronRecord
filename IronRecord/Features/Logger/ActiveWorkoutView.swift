//
//  ActiveWorkoutView.swift
//  IronRecord
//
//  Created by Codex on 17/02/26.
//

import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
    let session: WorkoutSession
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var saveErrorMessage: String?
    @State private var autoSaveTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                if groupedSets.isEmpty {
                    ContentUnavailableView(
                        "No Sets In This Session",
                        systemImage: "list.number",
                        description: Text("This workout has no generated set entries.")
                    )
                } else {
                    ForEach(groupedSets) { group in
                        Section {
                            ForEach(group.sets) { setEntry in
                                SetEntryRow(setEntry: setEntry)
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.exerciseName)
                                Text("Target reps: \(group.targetReps)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(session.templateName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        closeWorkout()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish Workout") {
                        finishWorkout()
                    }
                    .disabled(!canFinishWorkout)
                    .accessibilityHint("Completes this session once all sets have reps")
                }
            }
        }
        .onChange(of: autosaveState) { _, _ in
            scheduleAutoSave()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                saveSession()
            }
        }
        .onDisappear {
            autoSaveTask?.cancel()
            saveSession()
        }
        .alert(
            "Unable to Save Workout",
            isPresented: isShowingSaveError,
            actions: {
                Button("OK", role: .cancel) { }
            },
            message: {
                Text(saveErrorMessage ?? "An unknown error occurred.")
            }
        )
    }

    private var orderedSets: [SetEntry] {
        session.sets.sorted { left, right in
            if left.exercisePosition == right.exercisePosition {
                return left.setNumber < right.setNumber
            }
            return left.exercisePosition < right.exercisePosition
        }
    }

    private var groupedSets: [SetGroup] {
        let groups = Dictionary(grouping: orderedSets, by: \.exercisePosition)

        return groups.keys.sorted().compactMap { exercisePosition in
            guard let sets = groups[exercisePosition], let firstSet = sets.first else {
                return nil
            }

            return SetGroup(
                exercisePosition: exercisePosition,
                exerciseName: firstSet.exercise?.name ?? "Exercise \(exercisePosition)",
                targetReps: firstSet.targetRepsSnapshot.isEmpty ? "-" : firstSet.targetRepsSnapshot,
                sets: sets.sorted { $0.setNumber < $1.setNumber }
            )
        }
    }

    private var canFinishWorkout: Bool {
        !session.sets.isEmpty && session.sets.allSatisfy { $0.reps > 0 }
    }

    private var autosaveState: [SetAutosaveValue] {
        orderedSets.map { setEntry in
            SetAutosaveValue(
                weight: setEntry.weight,
                reps: setEntry.reps,
                rpe: setEntry.rpe,
                notes: setEntry.notes
            )
        }
    }

    private var isShowingSaveError: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    saveErrorMessage = nil
                }
            }
        )
    }

    private func closeWorkout() {
        saveSession()
        dismiss()
    }

    private func finishWorkout() {
        guard canFinishWorkout else {
            return
        }

        session.endedAt = .now
        saveSession()
        onFinished()
        dismiss()
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))

            guard !Task.isCancelled else {
                return
            }

            saveSession()
        }
    }

    private func saveSession() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

private struct SetEntryRow: View {
    @Bindable var setEntry: SetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set \(setEntry.setNumber)")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                TextField(
                    "kg",
                    value: $setEntry.weight,
                    format: .number.precision(.fractionLength(0 ... 2))
                )
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .accessibilityLabel("Weight in kilograms")

                TextField("Reps", value: $setEntry.reps, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .accessibilityLabel("Repetitions")

                TextField("RPE", text: rpeTextBinding)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("Rate of perceived exertion")
            }

            TextField("Notes (optional)", text: $setEntry.notes, axis: .vertical)
                .lineLimit(1 ... 2)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Set notes")
        }
        .accessibilityElement(children: .contain)
    }

    private var rpeTextBinding: Binding<String> {
        Binding(
            get: {
                guard let rpe = setEntry.rpe else {
                    return ""
                }

                return rpe.formatted(
                    .number.precision(.fractionLength(0 ... 1))
                )
            },
            set: { input in
                let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: ",", with: ".")

                if trimmedInput.isEmpty {
                    setEntry.rpe = nil
                    return
                }

                setEntry.rpe = Double(trimmedInput)
            }
        )
    }
}

private struct SetGroup: Identifiable {
    let exercisePosition: Int
    let exerciseName: String
    let targetReps: String
    let sets: [SetEntry]

    var id: Int { exercisePosition }
}

private struct SetAutosaveValue: Equatable {
    let weight: Double
    let reps: Int
    let rpe: Double?
    let notes: String
}
