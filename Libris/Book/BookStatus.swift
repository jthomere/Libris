//
//  BookStatus.swift
//  Libris
//

import SwiftUI

/// Where a book sits in the reading workflow.
///
/// `unsorted` is the default, "no decision yet" state. It's also the state a
/// book returns to when you tap its currently-active status again.
enum BookStatus: String, Codable, CaseIterable, Identifiable {
    case unsorted
    case notSure
    case toRead
    case didNotFinish
    case gaveUp
    case read
    case notInterested

    var id: String { rawValue }

    /// Human-readable label shown in the UI.
    var label: String {
        switch self {
        case .unsorted:     return "Unsorted"
        case .notSure:      return "Not Sure"
        case .toRead:       return "To Read"
        case .didNotFinish: return "Did Not Finish"
        case .gaveUp:       return "Gave Up"
        case .read:         return "Read"
        case .notInterested: return "Not Interested"
        }
    }

    /// SF Symbol used to represent the status.
    var systemImage: String {
        switch self {
        case .unsorted:     return "tray"
        case .notSure:      return "questionmark.circle"
        case .toRead:       return "bookmark"
        case .didNotFinish: return "book.closed"
        case .gaveUp:       return "xmark.circle"
        case .read:         return "checkmark.circle"
        case .notInterested: return "hand.thumbsdown"
        }
    }

    /// Accent color used to represent the status in the UI.
    var tint: Color {
        switch self {
        case .notSure:      return .teal
        case .toRead:       return .blue
        case .didNotFinish: return .orange
        case .gaveUp:       return .brown
        case .read:         return .green
        case .notInterested: return .gray
        case .unsorted:     return .secondary
        }
    }

    /// The statuses the user can explicitly assign via buttons. `unsorted` is
    /// omitted because it's the reset state rather than an action.
    static var actionable: [BookStatus] { [.toRead, .gaveUp, .read, .notSure, .didNotFinish, .notInterested] }
}
