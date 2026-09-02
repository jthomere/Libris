//
//  StatusPreset.swift
//  Libris
//

import Foundation

/// A named selection of statuses, applied from the Status filter menu's presets.
enum StatusPreset: CaseIterable {
    case all
    case keeping
    case interested
    case noStatus

    var label: String {
        switch self {
        case .all:         return "All"
        case .keeping:     return "Keeping"
        case .interested:  return "Interested"
        case .noStatus:    return "No Status"
        }
    }

    var statuses: Set<BookStatus?> {
        switch self {
        case .all:         return Self.allOptions
        case .keeping:     return Self.allOptions.subtracting([.notInterested])
        case .interested:  return [.toRead, .notSure, .didNotFinish]
        case .noStatus:    return [nil]
        }
    }

    static var allOptions: Set<BookStatus?> { Set(BookStatus.allCases.map(Optional.some) + [nil]) }
}
