//
//  Book.swift
//  Libris
//
//  The persistent model for a single book.
//

import Foundation
import SwiftData

@Model
final class Book {
    // Every attribute has a default value so the schema stays compatible with
    // CloudKit sync (CloudKit requires attributes to be optional or defaulted).
    var title: String = ""
    var author: String = ""
    var isbn: String = ""
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

    /// When the book was moved to the trash, or `nil` if it's still in the
    /// library. Doubles as the soft-delete flag and the "deleted on" timestamp:
    /// a trashed book is excluded from the library, filters, counts, export, and
    /// import dedupe until it's restored (`deletedDate = nil`) or permanently
    /// removed.
    var deletedDate: Date? = nil

    var status: BookStatus {
        get { BookStatus(rawValue: statusRaw) ?? .unsorted }
        set { statusRaw = newValue.rawValue }
    }

    /// Whether the book is currently in the trash.
    var isDeleted: Bool { deletedDate != nil }

    init(
        title: String = "",
        author: String = "",
        isbn: String = "",
        bookDescription: String = "",
        genre: String = "",
        rating: Double = 0,
        goodreadsURL: String = "",
        amazonURL: String = "",
        coverImageURL: String = "",
        note: String = "",
        tags: [String] = [],
        status: BookStatus = .unsorted,
        dateAdded: Date = Date(),
        deletedDate: Date? = nil
    ) {
        self.title = title
        self.author = author
        self.isbn = isbn
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
        self.deletedDate = deletedDate
    }

    /// Sets the status to `newStatus`, or resets to `.unsorted` if `newStatus`
    /// is already the active status.
    func toggleStatus(_ newStatus: BookStatus) {
        status = (status == newStatus) ? .unsorted : newStatus
    }
}
