import Foundation

struct ExercisePickerItem: Identifiable, Hashable {
    let id: String
    let name: String
    let bodyPart: ExerciseBodyPart
    let equipment: ExerciseEquipment
    let mode: ExerciseMode
}

struct FilterOption: Identifiable {
    let id: String
    let title: String
}

enum ExerciseFilterPicker: String, Identifiable {
    case bodyPart
    case equipment
    case mode

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bodyPart: return "Body Part"
        case .equipment: return "Equipment"
        case .mode: return "Exercise Mode"
        }
    }

    var allLabel: String {
        switch self {
        case .bodyPart: return "All Body Parts"
        case .equipment: return "All Equipment"
        case .mode: return "All Modes"
        }
    }
}

enum ExerciseEquipment: String, CaseIterable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case weightedBodyweight = "Weighted Bodyweight"
    case assistedBodyweight = "Assisted Bodyweight"
    case bodyweight = "Bodyweight"
    case cardio = "Cardio"
    case other = "Other"

    var id: String { rawValue }

    static var filterOrder: [ExerciseEquipment] {
        [
            .barbell,
            .dumbbell,
            .machine,
            .cable,
            .weightedBodyweight,
            .assistedBodyweight,
            .bodyweight,
            .cardio,
            .other
        ]
    }

    static func infer(equipment: String, exerciseName: String) -> ExerciseEquipment {
        if let mapped = exactEquipmentMap[normalized(equipment)] {
            return mapped
        }

        let combined = normalized("\(equipment) \(exerciseName)")
        let tokenSet = tokens(combined)

        if containsAny(tokenSet, cardioTokens) { return .cardio }
        if combined.contains("weighted bodyweight") { return .weightedBodyweight }
        if combined.contains("assisted bodyweight") { return .assistedBodyweight }
        if combined.contains("bodyweight") || combined.contains("pull up") { return .bodyweight }
        if containsAny(tokenSet, ["barbell"]) { return .barbell }
        if containsAny(tokenSet, ["dumbbell"]) { return .dumbbell }
        if containsAny(tokenSet, ["machine"]) || combined.contains("leg press") { return .machine }
        if containsAny(tokenSet, ["cable"]) { return .cable }

        return .other
    }

    private static let exactEquipmentMap: [String: ExerciseEquipment] = [
        "barbell": .barbell,
        "dumbbell": .dumbbell,
        "machine": .machine,
        "cable": .cable,
        "weighted bodyweight": .weightedBodyweight,
        "assisted bodyweight": .assistedBodyweight,
        "bodyweight": .bodyweight,
        "cardio": .cardio
    ]
}

enum ExerciseMode: String, CaseIterable, Identifiable {
    case weightedReps = "Weighted Reps"
    case repsOnly = "Reps Only"
    case cardioDuration = "Cardio Duration"

    var id: String { rawValue }

    static var filterOrder: [ExerciseMode] {
        [
            .weightedReps,
            .repsOnly,
            .cardioDuration
        ]
    }

    static func infer(equipment: String, exerciseName: String) -> ExerciseMode {
        let inferredEquipment = ExerciseEquipment.infer(
            equipment: equipment,
            exerciseName: exerciseName
        )

        switch inferredEquipment {
        case .cardio:
            return .cardioDuration
        case .barbell, .dumbbell, .machine, .cable, .weightedBodyweight:
            return .weightedReps
        case .assistedBodyweight, .bodyweight:
            return .repsOnly
        case .other:
            break
        }

        let combined = normalized("\(equipment) \(exerciseName)")
        let tokenSet = tokens(combined)
        if containsAny(tokenSet, cardioTokens) {
            return .cardioDuration
        }

        return .repsOnly
    }
}

enum ExerciseBodyPart: String, CaseIterable, Identifiable {
    case core = "Core"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case neck = "Neck"
    case traps = "Traps"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case abductors = "Abductors"
    case adductors = "Adductors"
    case calves = "Calves"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case others = "Others"

    var id: String { rawValue }

    static var filterOrder: [ExerciseBodyPart] {
        [
            .core,
            .chest,
            .back,
            .shoulders,
            .neck,
            .traps,
            .biceps,
            .triceps,
            .forearms,
            .quadriceps,
            .hamstrings,
            .glutes,
            .abductors,
            .adductors,
            .calves,
            .fullBody,
            .cardio,
            .others
        ]
    }

    static func fromStoredValue(_ rawValue: String) -> ExerciseBodyPart {
        let normalizedValue = normalized(rawValue)
        if let exactMatch = exactStoredValueMap[normalizedValue] {
            return exactMatch
        }

        return .others
    }

    private static let exactStoredValueMap: [String: ExerciseBodyPart] = [
        "core": .core,
        "chest": .chest,
        "back": .back,
        "upper back": .traps,
        "shoulders": .shoulders,
        "neck": .neck,
        "traps": .traps,
        "biceps": .biceps,
        "triceps": .triceps,
        "forearms": .forearms,
        "quadriceps": .quadriceps,
        "quads": .quadriceps,
        "hamstrings": .hamstrings,
        "glutes": .glutes,
        "abductors": .abductors,
        "adductors": .adductors,
        "calves": .calves,
        "full body": .fullBody,
        "cardio": .cardio,
        // Keep these generic buckets intentionally unresolved to avoid
        // forcing broad labels when we can infer more specific parts from name.
        "arms": .others,
        "legs": .others
    ]
}

private let cardioTokens: Set<String> = [
    "cardio",
    "bike",
    "run",
    "rower",
    "erg",
    "treadmill"
]

private func normalized(_ value: String) -> String {
    tokens(value).joined(separator: " ")
}

private func tokens(_ value: String) -> [String] {
    value
        .lowercased()
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
}

private func containsAny(_ tokenSet: [String], _ expected: Set<String>) -> Bool {
    !Set(tokenSet).isDisjoint(with: expected)
}

private func containsAny(_ tokenSet: [String], _ expected: [String]) -> Bool {
    containsAny(tokenSet, Set(expected))
}
