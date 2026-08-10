//
//  BookStatus.swift
//  Libris
//

import Foundation

/// Where a book sits in the reading workflow.
///
/// `unsorted` is the default, "no decision yet" state. It's also the state a
/// book returns to when you tap its currently-active status again.
enum BookStatus: String, Codable, CaseIterable, Identifiable {
    case unsorted
    case toRead
    case read
    case toRemove

    var id: String { rawValue }

    /// Human-readable label shown in the UI.
    var label: String {
        switch self {
        case .unsorted: return "Unsorted"
        case .toRead:   return "To Read"
        case .read:     return "Read"
        case .toRemove: return "To Remove"
        }
    }

    /// SF Symbol used to represent the status.
    var systemImage: String {
        switch self {
        case .unsorted: return "tray"
        case .toRead:   return "bookmark"
        case .read:     return "checkmark.circle"
        case .toRemove: return "trash"
        }
    }

    /// The statuses the user can explicitly assign via buttons. `unsorted` is
    /// omitted because it's the reset state rather than an action.
    static var actionable: [BookStatus] { [.toRead, .read, .toRemove] }
}
