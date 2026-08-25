//
//  StatusPreset.swift
//  Libris
//

import Foundation

/// A named selection of statuses for the status filter. `custom` isn't a preset
/// to apply — it's what the current selection reads as when it matches none of
/// the named ones.
enum StatusPreset: CaseIterable {
    case all
    case `default`
    case notInterested
    case none

    var label: String {
        switch self {
        case .all:              return "All"
        case .default:          return "Default"
        case .notInterested:    return "Not Interested"
        case .none:             return "Hide All"
        }
    }

    var statuses: Set<BookStatus?> {
        switch self {
        case .all:              return Self.allOptions
        case .default:          return Self.allOptions.subtracting([.notInterested])
        case .notInterested:    return [.notInterested]
        case .none:             return []
        }
    }

    static var allOptions: Set<BookStatus?> { Set(BookStatus.allCases.map(Optional.some) + [nil]) }

    /// The preset whose statuses equal `statuses`, or `nil` when the selection
    /// is custom.
    static func matching(_ statuses: Set<BookStatus?>) -> StatusPreset? {
        allCases.first { $0.statuses == statuses }
    }
}
