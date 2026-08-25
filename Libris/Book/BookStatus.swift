//
//  BookStatus.swift
//  Libris
//

import SwiftUI

/// Where a book sits in the reading workflow.
///
/// A book's status is optional: `nil` means "no decision yet" — the default for
/// new and imported books, and the state a book returns to when you tap its
/// currently-active status again.
enum BookStatus: String, Codable, CaseIterable, Identifiable {
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
        }
    }

    /// The statuses the user can explicitly assign via buttons. Assigning the
    /// active status again clears it back to `nil` rather than being an action.
    static var actionable: [BookStatus] { [.toRead, .gaveUp, .read, .notSure, .didNotFinish, .notInterested] }
}

extension Optional where Wrapped == BookStatus {
    var facetLabel: String { self?.label ?? "No Status" }
    var facetSystemImage: String? { self?.systemImage }
    var facetTint: Color { self?.tint ?? .secondary }
}
