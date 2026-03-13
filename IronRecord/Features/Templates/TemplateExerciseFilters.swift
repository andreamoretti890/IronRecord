import Foundation
import SwiftData

struct ExercisePickerItem: Identifiable, Hashable {
    let id: PersistentIdentifier
    let name: String
    let primaryBodyParts: [ExerciseBodyPart]
    let secondaryBodyParts: [ExerciseBodyPart]
    let equipment: ExerciseEquipment
    let mode: ExerciseMode
    let source: ExercisePickerSource

    var allBodyParts: [ExerciseBodyPart] {
        ExerciseBodyPart.filterOrder.filter { bodyPart in
            primaryBodyParts.contains(bodyPart) || secondaryBodyParts.contains(bodyPart)
        }
    }
}

enum ExercisePickerSource: Hashable {
    case catalog
    case custom
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
    case band = "Band"
    case barbell = "Barbell"
    case cableDouble = "Cable (Double)"
    case cableSingle = "Cable (Single)"
    case dumbellDouble = "Dumbell (Double)"
    case dumbellSingle = "Dumbell (Single)"
    case ezBar = "EZ Bar"
    case bodyweight = "Bodyweight"
    case cardio = "Cardio"
    case kettlebellDouble = "Kettlebell (Double)"
    case kettlebellSingle = "Kettlebell (Single)"
    case machine = "Machine"
    case machineAssisted = "Machine Assisted"
    case other = "Other"
    case rope = "Rope"
    case smithMachine = "Smith Machine"
    case trx = "TRX"
    case weightedBall = "Weighted Ball"

    var id: String { rawValue }

    static var filterOrder: [ExerciseEquipment] {
        allCases.sorted { $0.rawValue < $1.rawValue }
    }

    static func infer(equipment: String, exerciseName: String) -> ExerciseEquipment {
        if let mapped = exactEquipmentMap[normalized(equipment)] {
            return mapped
        }

        let combined = normalized("\(equipment) \(exerciseName)")
        let tokenSet = tokens(combined)

        if containsAny(tokenSet, cardioTokens) { return .cardio }
        if combined.contains("machine assisted") || combined.contains("assisted machine") {
            return .machineAssisted
        }
        if combined.contains("smith machine") {
            return .smithMachine
        }
        if combined.contains("ez bar") || combined.contains("ezbar") || combined.contains("curl bar") {
            return .ezBar
        }
        if combined.contains("weighted ball") || combined.contains("medicine ball") || combined.contains("med ball") || combined.contains("slam ball") {
            return .weightedBall
        }
        if containsAny(tokenSet, ["trx"]) { return .trx }
        if containsAny(tokenSet, ["rope"]) { return .rope }
        if containsAny(tokenSet, ["band", "bands"]) || combined.contains("resistance band") {
            return .band
        }
        if combined.contains("double kettlebell") || combined.contains("double kb") {
            return .kettlebellDouble
        }
        if combined.contains("single kettlebell") || combined.contains("single kb") {
            return .kettlebellSingle
        }
        if containsAny(tokenSet, ["kettlebell", "kettlebells", "kb"]) {
            return .kettlebellSingle
        }
        if combined.contains("bodyweight") || combined.contains("pull up") { return .bodyweight }
        if containsAny(tokenSet, ["barbell"]) { return .barbell }
        if containsAny(tokenSet, ["dumbbell", "dumbell"]) {
            return combined.contains("single") ? .dumbellSingle : .dumbellDouble
        }
        if containsAny(tokenSet, ["machine"]) || combined.contains("leg press") { return .machine }
        if containsAny(tokenSet, ["cable"]) {
            return combined.contains("single") ? .cableSingle : .cableDouble
        }

        return .other
    }

    private static let exactEquipmentMap: [String: ExerciseEquipment] = [
        "band": .band,
        "barbell": .barbell,
        "cable": .cableDouble,
        "cable double": .cableDouble,
        "double cable": .cableDouble,
        "cable single": .cableSingle,
        "single cable": .cableSingle,
        "dumbbell": .dumbellDouble,
        "dumbell": .dumbellDouble,
        "dumbbell double": .dumbellDouble,
        "dumbell double": .dumbellDouble,
        "double dumbbell": .dumbellDouble,
        "double dumbell": .dumbellDouble,
        "dumbbell single": .dumbellSingle,
        "dumbell single": .dumbellSingle,
        "single dumbbell": .dumbellSingle,
        "single dumbell": .dumbellSingle,
        "ez bar": .ezBar,
        "ezbar": .ezBar,
        "curl bar": .ezBar,
        "kettlebell": .kettlebellSingle,
        "single kettlebell": .kettlebellSingle,
        "kettlebell single": .kettlebellSingle,
        "double kettlebell": .kettlebellDouble,
        "kettlebell double": .kettlebellDouble,
        "machine": .machine,
        "machine assisted": .machineAssisted,
        "bodyweight": .bodyweight,
        "cardio": .cardio,
        "rope": .rope,
        "smith machine": .smithMachine,
        "trx": .trx,
        "weighted ball": .weightedBall,
        "medicine ball": .weightedBall
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
        case .band, .barbell, .cableDouble, .cableSingle, .dumbellDouble, .dumbellSingle,
             .ezBar, .kettlebellDouble, .kettlebellSingle, .machine, .machineAssisted,
             .rope, .smithMachine, .trx, .weightedBall:
            return .weightedReps
        case .bodyweight:
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

enum ExerciseBodyPart: String, CaseIterable, Identifiable, Codable {
    case abs = "Abs"
    case abductors = "Abductors"
    case adductors = "Adductors"
    case biceps = "Biceps"
    case calves = "Calves"
    case cardio = "Cardio"
    case chest = "Chest"
    case forearms = "Forearms"
    case glutes = "Glutes"
    case hamstrings = "Hamstrings"
    case hipFlexors = "Hip Flexors"
    case lats = "Lats"
    case lowerBack = "Lower Back"
    case middleBack = "Middle Back"
    case neck = "Neck"
    case obliques = "Obliques"
    case fullBody = "Full Body"
    case others = "Others"
    case quads = "Quads"
    case rotatorCuff = "Rotator Cuff"
    case shoulders = "Shoulders"
    case traps = "Traps"
    case triceps = "Triceps"
    case upperBack = "Upper Back"

    var id: String { rawValue }

    static var filterOrder: [ExerciseBodyPart] {
        allCases.sorted { $0.rawValue < $1.rawValue }
    }

    static func fromStoredValue(_ rawValue: String) -> ExerciseBodyPart {
        let normalizedValue = normalized(rawValue)
        if let exactMatch = exactStoredValueMap[normalizedValue] {
            return exactMatch
        }

        return .others
    }

    static func fromExercise(name: String, storedBodyPart: String) -> ExerciseBodyPart {
        let normalizedName = normalized(name)
        if let exactMatch = exactExerciseNameMap[normalizedName] {
            return exactMatch
        }

        return fromStoredValue(storedBodyPart)
    }

    private static let exactStoredValueMap: [String: ExerciseBodyPart] = [
        "abs": .abs,
        "core": .abs,
        "abdominals": .abs,
        "abductors": .abductors,
        "adductors": .adductors,
        "biceps": .biceps,
        "calves": .calves,
        "cardio": .cardio,
        "chest": .chest,
        "forearms": .forearms,
        "glutes": .glutes,
        "hamstrings": .hamstrings,
        "hip flexors": .hipFlexors,
        "lats": .lats,
        "latissimus dorsi": .lats,
        "lower back": .lowerBack,
        "middle back": .middleBack,
        "mid back": .middleBack,
        "neck": .neck,
        "obliques": .obliques,
        "full body": .fullBody,
        "quadriceps": .quads,
        "quads": .quads,
        "rotator cuff": .rotatorCuff,
        "shoulders": .shoulders,
        "traps": .traps,
        "triceps": .triceps,
        "upper back": .upperBack,
        "back": .middleBack,
        // Keep these generic buckets intentionally unresolved to avoid
        // forcing broad labels when we can infer more specific parts from name.
        "arms": .others,
        "legs": .others
    ]

    private static let exactExerciseNameMap: [String: ExerciseBodyPart] = [
        "back squat": .quads,
        "barbell bench press": .chest,
        "barbell overhead press": .shoulders,
        "barbell row": .middleBack,
        "cable lateral raise": .shoulders,
        "chest supported row": .middleBack,
        "conventional deadlift": .lowerBack,
        "dumbbell biceps curl": .biceps,
        "face pull": .upperBack,
        "front squat": .quads,
        "hack squat": .quads,
        "hammer curl": .forearms,
        "hip thrust": .glutes,
        "incline dumbbell press": .chest,
        "lat pulldown": .lats,
        "leg extension": .quads,
        "leg press": .quads,
        "lying leg curl": .hamstrings,
        "machine chest press": .chest,
        "pull up": .lats,
        "romanian deadlift": .hamstrings,
        "seated cable row": .middleBack,
        "seated dumbbell shoulder press": .shoulders,
        "standing calf raise": .calves,
        "triceps rope pushdown": .triceps
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

@MainActor
extension Exercise {
    var pickerItem: ExercisePickerItem {
        ExercisePickerItem(
            id: persistentModelID,
            name: name,
            primaryBodyParts: primaryBodyParts,
            secondaryBodyParts: secondaryBodyParts,
            equipment: ExerciseEquipment.infer(
                equipment: equipment,
                exerciseName: name
            ),
            mode: ExerciseMode.infer(
                equipment: equipment,
                exerciseName: name
            ),
            source: category == "Custom" ? .custom : .catalog
        )
    }
}

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
