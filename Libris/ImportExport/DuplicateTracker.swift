//
//  DuplicateTracker.swift
//  Libris
//

import Foundation

/// Tracks the ISBNs and title+author pairs already seen, so import can skip
/// duplicates against both the existing library and earlier books in the same
/// file. A blank title carries no title+author identity, so such a book can
/// only be matched (and remembered) by its ISBN.
struct DuplicateTracker {
    private var seenISBNs: Set<String> = []
    private var seenTitleAuthors: Set<String> = []

    init(existingBooks: [Book]) {
        for book in existingBooks {
            remember(title: book.title, author: book.author, isbn: book.isbn)
        }
    }

    func isDuplicate(title: String, author: String, isbn: String) -> Bool {
        let isbnKey = Self.normalizedISBN(isbn)
        if !isbnKey.isEmpty && seenISBNs.contains(isbnKey) { return true }
        if !title.isEmpty && seenTitleAuthors.contains(Self.titleAuthorKey(title: title, author: author)) {
            return true
        }
        return false
    }

    mutating func remember(title: String, author: String, isbn: String) {
        let isbnKey = Self.normalizedISBN(isbn)
        if !isbnKey.isEmpty { seenISBNs.insert(isbnKey) }
        if !title.isEmpty { seenTitleAuthors.insert(Self.titleAuthorKey(title: title, author: author)) }
    }

    /// Reduces an ISBN to its significant characters so formatting differences
    /// don't defeat duplicate detection. Returns "" when there's nothing usable.
    private static func normalizedISBN(_ value: String) -> String {
        value.uppercased().filter { $0.isNumber || $0 == "X" }
    }

    private static func titleAuthorKey(title: String, author: String) -> String {
        "\(title.lowercased())|\(author.lowercased())"
    }
}
