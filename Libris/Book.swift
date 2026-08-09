//
//  Book.swift
//  Libris
//
//  The persistent model for a single book, plus its status.
//

import Foundation
import SwiftData

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

@Model
final class Book {
    // Every attribute has a default value so the schema stays compatible with
    // CloudKit sync (CloudKit requires attributes to be optional or defaulted).
    var title: String = ""
    var author: String = ""
    var bookDescription: String = ""
    var genre: String = ""
    var rating: Double = 0
    var goodreadsURL: String = ""
    var amazonURL: String = ""
    var coverImageURL: String = ""
    var note: String = ""
    var tags: [String] = []

    /// Backing storage for the status. Stored as the raw string so it's stable
    /// across schema changes and easy to sync. Use `status` to read/write.
    var statusRaw: String = BookStatus.unsorted.rawValue

    /// When the book was added, used as a stable secondary sort key.
    var dateAdded: Date = Date()

    var status: BookStatus {
        get { BookStatus(rawValue: statusRaw) ?? .unsorted }
        set { statusRaw = newValue.rawValue }
    }

    init(
        title: String = "",
        author: String = "",
        bookDescription: String = "",
        genre: String = "",
        rating: Double = 0,
        goodreadsURL: String = "",
        amazonURL: String = "",
        coverImageURL: String = "",
        note: String = "",
        tags: [String] = [],
        status: BookStatus = .unsorted,
        dateAdded: Date = Date()
    ) {
        self.title = title
        self.author = author
        self.bookDescription = bookDescription
        self.genre = genre
        self.rating = rating
        self.goodreadsURL = goodreadsURL
        self.amazonURL = amazonURL
        self.coverImageURL = coverImageURL
        self.note = note
        self.tags = tags
        self.statusRaw = status.rawValue
        self.dateAdded = dateAdded
    }

    /// Sets the status to `newStatus`, or resets to `.unsorted` if `newStatus`
    /// is already the active status.
    func toggleStatus(_ newStatus: BookStatus) {
        status = (status == newStatus) ? .unsorted : newStatus
    }
}
