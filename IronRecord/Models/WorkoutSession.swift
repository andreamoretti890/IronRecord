import Foundation
import SwiftData

@Model
final class WorkoutSession: Identifiable {
    var templateName: String
    var startedAt: Date
    var completedAt: Date?
    var pausedAt: Date?
    var accumulatedPausedDuration: TimeInterval
    var activeRestStartedAt: Date?
    var activeRestDurationSeconds: Int
    var activeRestPausedRemainingSeconds: Int?
    var activeRestExercisePosition: Int?
    var activeRestSetPosition: Int?
    var stateRawValue: String

    var sourceTemplate: WorkoutTemplate?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSessionExercise.session)
    var exercises: [WorkoutSessionExercise]

    init(
        templateName: String,
        startedAt: Date = .now,
        sourceTemplate: WorkoutTemplate? = nil
    ) {
        self.templateName = templateName
        self.startedAt = startedAt
        self.sourceTemplate = sourceTemplate
        completedAt = nil
        pausedAt = nil
        accumulatedPausedDuration = 0
        activeRestStartedAt = nil
        activeRestDurationSeconds = 0
        activeRestPausedRemainingSeconds = nil
        activeRestExercisePosition = nil
        activeRestSetPosition = nil
        stateRawValue = WorkoutSessionState.active.rawValue
        exercises = []
    }
}

@Model
final class WorkoutSessionExercise: Identifiable {
    var position: Int
    var exerciseName: String
    var notes: String
    var defaultRestSeconds: Int

    var session: WorkoutSession?
    var sourceTemplateExercise: TemplateExercise?
    var sourceExercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSessionSet.sessionExercise)
    var sets: [WorkoutSessionSet]

    init(
        position: Int,
        exerciseName: String,
        notes: String,
        defaultRestSeconds: Int,
        session: WorkoutSession? = nil,
        sourceTemplateExercise: TemplateExercise? = nil,
        sourceExercise: Exercise? = nil
    ) {
        self.position = position
        self.exerciseName = exerciseName
        self.notes = notes
        self.defaultRestSeconds = defaultRestSeconds
        self.session = session
        self.sourceTemplateExercise = sourceTemplateExercise
        self.sourceExercise = sourceExercise
        sets = []
    }
}

@Model
final class WorkoutSessionSet: Identifiable {
    var position: Int
    var prescribedWeight: Double?
    var targetReps: Int?
    var targetRepMin: Int?
    var targetRepMax: Int?
    var restSeconds: Int
    var typeRawValue: String
    var loggedWeight: Double?
    var loggedReps: Int?
    var isCompleted: Bool
    var completedAt: Date?

    var sessionExercise: WorkoutSessionExercise?
    var sourceTemplateSet: TemplateExerciseSet?

    init(
        position: Int,
        prescribedWeight: Double? = nil,
        targetReps: Int? = nil,
        targetRepMin: Int? = nil,
        targetRepMax: Int? = nil,
        restSeconds: Int,
        typeRawValue: String,
        loggedWeight: Double? = nil,
        loggedReps: Int? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        sessionExercise: WorkoutSessionExercise? = nil,
        sourceTemplateSet: TemplateExerciseSet? = nil
    ) {
        self.position = position
        self.prescribedWeight = prescribedWeight
        self.targetReps = targetReps
        self.targetRepMin = targetRepMin
        self.targetRepMax = targetRepMax
        self.restSeconds = restSeconds
        self.typeRawValue = typeRawValue
        self.loggedWeight = loggedWeight
        self.loggedReps = loggedReps
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.sessionExercise = sessionExercise
        self.sourceTemplateSet = sourceTemplateSet
    }
}

enum WorkoutSessionState: String, CaseIterable, Codable {
    case active
    case paused
    case completed
}

extension WorkoutSession {
    var state: WorkoutSessionState {
        get { WorkoutSessionState(rawValue: stateRawValue) ?? .active }
        set { stateRawValue = newValue.rawValue }
    }

    var isInProgress: Bool {
        state != .completed
    }

    var sortedExercises: [WorkoutSessionExercise] {
        exercises.sorted { left, right in
            left.position < right.position
        }
    }

    var activeRestIdentifier: WorkoutRestIdentifier? {
        guard let exercisePosition = activeRestExercisePosition,
              let setPosition = activeRestSetPosition
        else {
            return nil
        }

        return WorkoutRestIdentifier(
            exercisePosition: exercisePosition,
            setPosition: setPosition
        )
    }

    func pause(at date: Date = .now) {
        guard state == .active else {
            return
        }

        pausedAt = date
        state = .paused

        if let remainingSeconds = activeRestRemainingSeconds(at: date) {
            activeRestPausedRemainingSeconds = remainingSeconds
        }
    }

    func resume(at date: Date = .now) {
        guard state == .paused,
              let pausedAt
        else {
            return
        }

        accumulatedPausedDuration += date.timeIntervalSince(pausedAt)
        self.pausedAt = nil
        state = .active

        if let pausedRemaining = activeRestPausedRemainingSeconds {
            if pausedRemaining > 0 {
                activeRestDurationSeconds = pausedRemaining
                activeRestStartedAt = date
            } else {
                clearActiveRest()
            }

            activeRestPausedRemainingSeconds = nil
        }
    }

    func finish(at date: Date = .now) {
        if state == .paused {
            resume(at: date)
        }

        completedAt = date
        state = .completed
        clearActiveRest()
    }

    func activateRestTimer(
        for set: WorkoutSessionSet,
        in exercise: WorkoutSessionExercise,
        at date: Date = .now
    ) {
        let restSeconds = set.effectiveRestSeconds
        guard restSeconds > 0 else {
            clearActiveRest()
            return
        }

        activeRestDurationSeconds = restSeconds
        activeRestStartedAt = date
        activeRestPausedRemainingSeconds = nil
        activeRestExercisePosition = exercise.position
        activeRestSetPosition = set.position
    }

    func clearActiveRest() {
        activeRestStartedAt = nil
        activeRestDurationSeconds = 0
        activeRestPausedRemainingSeconds = nil
        activeRestExercisePosition = nil
        activeRestSetPosition = nil
    }

    func activeRestRemainingSeconds(at date: Date = .now) -> Int? {
        let totalSeconds: Int

        if let pausedRemaining = activeRestPausedRemainingSeconds {
            totalSeconds = pausedRemaining
        } else if let activeRestStartedAt, activeRestDurationSeconds > 0 {
            let elapsed = Int(date.timeIntervalSince(activeRestStartedAt).rounded(.down))
            totalSeconds = max(activeRestDurationSeconds - elapsed, 0)
        } else {
            return nil
        }

        return totalSeconds
    }

    static func make(from template: WorkoutTemplate, startedAt: Date = .now) -> WorkoutSession {
        let session = WorkoutSession(
            templateName: template.name,
            startedAt: startedAt,
            sourceTemplate: template
        )

        session.exercises = template.sortedExercises.map { templateExercise in
            let sessionExercise = WorkoutSessionExercise(
                position: templateExercise.position,
                exerciseName: templateExercise.displayName,
                notes: templateExercise.notes,
                defaultRestSeconds: templateExercise.restSeconds,
                session: session,
                sourceTemplateExercise: templateExercise,
                sourceExercise: templateExercise.exercise
            )

            let templateSets = templateExercise.sortedPrescribedSets
            let sessionSets = if templateSets.isEmpty {
                makeFallbackSets(from: templateExercise, sessionExercise: sessionExercise)
            } else {
                templateSets.map { templateSet in
                    WorkoutSessionSet(
                        position: templateSet.position,
                        prescribedWeight: templateSet.prescribedWeight,
                        targetReps: templateSet.targetReps,
                        targetRepMin: templateSet.targetRepMin,
                        targetRepMax: templateSet.targetRepMax,
                        restSeconds: templateSet.effectiveRestSeconds,
                        typeRawValue: templateSet.typeRawValue,
                        loggedWeight: templateSet.prescribedWeight,
                        loggedReps: initialLoggedReps(
                            targetReps: templateSet.targetReps,
                            targetRepMin: templateSet.targetRepMin,
                            targetRepMax: templateSet.targetRepMax
                        ),
                        sessionExercise: sessionExercise,
                        sourceTemplateSet: templateSet
                    )
                }
            }

            sessionExercise.sets = sessionSets
            return sessionExercise
        }

        return session
    }

    private static func makeFallbackSets(
        from templateExercise: TemplateExercise,
        sessionExercise: WorkoutSessionExercise
    ) -> [WorkoutSessionSet] {
        let repTarget = RepTarget.parse(templateExercise.targetReps)

        return (1...templateExercise.targetSets).map { setPosition in
            WorkoutSessionSet(
                position: setPosition,
                prescribedWeight: nil,
                targetReps: repTarget.exactReps,
                targetRepMin: repTarget.repMin,
                targetRepMax: repTarget.repMax,
                restSeconds: templateExercise.restSeconds,
                typeRawValue: TemplateSetType.normal.rawValue,
                loggedWeight: nil,
                loggedReps: initialLoggedReps(
                    targetReps: repTarget.exactReps,
                    targetRepMin: repTarget.repMin,
                    targetRepMax: repTarget.repMax
                ),
                sessionExercise: sessionExercise
            )
        }
    }

    private static func initialLoggedReps(
        targetReps: Int?,
        targetRepMin: Int?,
        targetRepMax: Int?
    ) -> Int? {
        if let targetReps {
            return targetReps
        }

        if let targetRepMax {
            return targetRepMax
        }

        return targetRepMin
    }
}

extension WorkoutSessionExercise {
    var sortedSets: [WorkoutSessionSet] {
        sets.sorted { left, right in
            left.position < right.position
        }
    }

    var displayEquipmentText: String? {
        let value = sourceExercise?.equipment.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var displayTargetSummary: String {
        let setTargets = sortedSets
            .map(\.targetDisplayText)
            .filter { !$0.isEmpty }

        guard !setTargets.isEmpty else {
            return "Log your working sets"
        }

        let uniqueTargets = Array(Set(setTargets)).sorted()
        return uniqueTargets.joined(separator: " • ")
    }
}

extension WorkoutSessionSet {
    var setType: TemplateSetType {
        get { TemplateSetType(rawValue: typeRawValue) ?? .normal }
        set { typeRawValue = newValue.rawValue }
    }

    var effectiveRestSeconds: Int {
        if restSeconds > 0 {
            return restSeconds
        }

        return sessionExercise?.defaultRestSeconds ?? 0
    }

    var targetDisplayText: String {
        if let targetRepMin, let targetRepMax {
            return "\(targetRepMin)-\(targetRepMax) reps"
        }

        if let targetReps {
            return "\(targetReps) reps"
        }

        return ""
    }

    var loggedWeightText: String {
        guard let loggedWeight = loggedWeight ?? prescribedWeight else {
            return ""
        }

        if loggedWeight == floor(loggedWeight) {
            return String(Int(loggedWeight))
        }

        return loggedWeight.formatted(
            .number.precision(.fractionLength(0 ... 2))
        )
    }

    var loggedRepsText: String {
        guard let loggedReps = loggedReps ?? targetReps ?? targetRepMax ?? targetRepMin else {
            return ""
        }

        return String(loggedReps)
    }
}

struct WorkoutRestIdentifier: Equatable {
    let exercisePosition: Int
    let setPosition: Int
}

private struct RepTarget {
    let exactReps: Int?
    let repMin: Int?
    let repMax: Int?

    nonisolated static func parse(_ rawValue: String) -> RepTarget {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return RepTarget(exactReps: nil, repMin: nil, repMax: nil)
        }

        if let exact = Int(trimmedValue) {
            return RepTarget(exactReps: exact, repMin: nil, repMax: nil)
        }

        let components = trimmedValue.split(separator: "-", maxSplits: 1).map(String.init)
        if components.count == 2,
           let min = Int(components[0].trimmingCharacters(in: .whitespacesAndNewlines)),
           let max = Int(components[1].trimmingCharacters(in: .whitespacesAndNewlines))
        {
            return RepTarget(exactReps: nil, repMin: min, repMax: max)
        }

        return RepTarget(exactReps: nil, repMin: nil, repMax: nil)
    }
}
