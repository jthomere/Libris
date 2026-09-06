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
    case toRead
    case read
    case didNotFinish
    case notSure
    case gaveUp
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

    /// Accent color used to represent the status in the UI.
    var tint: Color {
        switch self {
        case .toRead:        return .blue
        case .read:          return Color(red: 0.30, green: 0.52, blue: 0.37)
        case .notSure:       return Color(red: 0.44, green: 0.44, blue: 0.47)
        case .didNotFinish:  return Color(red: 0.72, green: 0.60, blue: 0.47)
        case .gaveUp:        return Color(red: 0.36, green: 0.26, blue: 0.19)
        case .notInterested: return Color(red: 0.30, green: 0.30, blue: 0.33)
        }
    }

    var onTint: Color {
        switch self {
        case .didNotFinish: return Color(red: 0.28, green: 0.20, blue: 0.12)
        default:            return .white
        }
    }

    /// The statuses the user can explicitly assign via buttons. Assigning the
    /// active status again clears it back to `nil` rather than being an action.
    /// Every status is assignable, so this follows the canonical `allCases` order.
    static var actionable: [BookStatus] { allCases }
}

extension Optional where Wrapped == BookStatus {
    var facetLabel: String { self?.label ?? "No Status" }
    var facetTint: Color { self?.tint ?? .secondary }

    /// Ordering used when sorting by status: `nil` ("No Status") sorts first,
    /// then statuses follow the canonical `allCases` order.
    var sortRank: Int {
        guard let value = self else { return -1 }
        return BookStatus.allCases.firstIndex(of: value) ?? 0
    }
}
