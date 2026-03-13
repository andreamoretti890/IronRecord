import SwiftUI

extension TemplateSetType {
    static let menuPrimaryCases: [TemplateSetType] = [.normal, .warmUp, .failure]

    var countsTowardDisplayedSetNumber: Bool {
        switch self {
        case .normal, .failure:
            true
        case .warmUp, .drop:
            false
        }
    }

    var menuTitle: String {
        switch self {
        case .normal:
            "Normal"
        case .warmUp:
            "Warm Up"
        case .failure:
            "Failure"
        case .drop:
            "Dropset"
        }
    }

    var menuSystemImage: String {
        switch self {
        case .normal:
            "circle"
        case .warmUp:
            "flame.fill"
        case .failure:
            "exclamationmark.triangle"
        case .drop:
            "arrow.down.circle"
        }
    }

    var rowSystemImage: String {
        switch self {
        case .normal:
            "circle"
        case .warmUp:
            "flame.fill"
        case .failure:
            "exclamationmark.triangle.fill"
        case .drop:
            "arrow.down"
        }
    }

    var rowForegroundColor: Color {
        switch self {
        case .normal:
            .primary
        case .warmUp:
            .orange
        case .failure:
            .red
        case .drop:
            .blue
        }
    }

    var rowBackgroundColor: Color {
        switch self {
        case .normal:
            Color(.tertiarySystemBackground)
        case .warmUp:
            .orange.opacity(0.14)
        case .failure:
            .red.opacity(0.14)
        case .drop:
            .blue.opacity(0.14)
        }
    }

    var rowBorderColor: Color {
        switch self {
        case .normal:
            Color.secondary.opacity(0.18)
        case .warmUp:
            .orange.opacity(0.32)
        case .failure:
            .red.opacity(0.32)
        case .drop:
            .blue.opacity(0.32)
        }
    }
}
