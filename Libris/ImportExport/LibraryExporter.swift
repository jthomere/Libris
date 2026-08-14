//
//  LibraryExporter.swift
//  Libris
//
//  The mirror of ImportParser: serializes the library into a Libris library
//  file. Kept separate from the UI so it can be tested directly.
//

import Foundation

enum LibraryExporter {
    static let schemaVersion = ImportParser.latestVersion

    /// Encodes `books` into the JSON bytes of a Libris backup file.
    static func export(_ books: [Book]) throws -> Data {
        let file = LibraryFile(
            schemaVersion: schemaVersion,
            records: books.map { record(for: $0) },
            kind: LibraryFile.backupKind
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = LibraryDateCoding.encoding
        return try encoder.encode(file)
    }

    private static func record(for book: Book) -> BookRecord {
        BookRecord(
            title: book.title,
            author: nonEmpty(book.author),
            isbn: nonEmpty(book.isbn),
            bookDescription: nonEmpty(book.bookDescription),
            genre: nonEmpty(book.genre),
            rating: book.rating,
            note: nonEmpty(book.note),
            tags: book.tags.isEmpty ? nil : book.tags,
            goodreadsURL: nonEmpty(book.goodreadsURL),
            amazonURL: nonEmpty(book.amazonURL),
            coverImageURL: nonEmpty(book.coverImageURL),
            status: book.status.rawValue,
            dateAdded: book.dateAdded
        )
    }

    /// `nil` for an empty or whitespace-only string, so the encoder omits the key.
    private static func nonEmpty(_ value: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
    }
}
