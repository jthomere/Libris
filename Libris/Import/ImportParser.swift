//
//  ImportParser.swift
//  Libris
//
//  Turns the raw bytes of an import file into books to add, skipping any book
//  that already exists in the library or earlier in the file. A book is a
//  duplicate if its ISBN (when present) or its title+author matches. The file
//  is always treated as a batch to add: existing books are never touched.
//  Kept separate from the UI so it can be tested directly.
//

import Foundation

enum ImportParser {
    /// The one schema version this build understands. A file declaring any
    /// other version is rejected rather than parsed under the wrong rules.
    static let supportedVersion = 1

    struct Result {
        var toAdd: [Book]
        var duplicateCount: Int
    }

    enum ImportError: LocalizedError {
        case invalidFile
        case unsupportedVersion(Int)

        var errorDescription: String? {
            switch self {
            case .invalidFile:
                return "This file isn’t a valid Libris import file."
            case .unsupportedVersion(let version):
                return "This file uses import format version \(version), which this version of Libris doesn’t support. Update Libris and try again."
            }
        }
    }

    /// Parses `data`, throwing `ImportError` if it isn't a readable import file
    /// or declares an unsupported version.
    static func parse(_ data: Data, existingBooks: [Book]) throws -> Result {
        let decoder = JSONDecoder()

        // Check the version before decoding the books, so a newer file reports
        // an unsupported version rather than a confusing parse failure.
        guard let probe = try? decoder.decode(VersionProbe.self, from: data) else {
            throw ImportError.invalidFile
        }
        guard probe.schemaVersion == supportedVersion else {
            throw ImportError.unsupportedVersion(probe.schemaVersion)
        }

        guard let file = try? decoder.decode(ImportFile.self, from: data) else {
            throw ImportError.invalidFile
        }

        var seenISBNs = Set(existingBooks.map { normalizedISBN($0.isbn) }.filter { !$0.isEmpty })
        var seenTitleAuthors = Set(existingBooks.map { titleAuthorKey(title: $0.title, author: $0.author) })
        var toAdd: [Book] = []
        var duplicates = 0

        for incoming in file.books {
            let title = incoming.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            let author = trimmed(incoming.author)

            let isbnRaw = trimmed(incoming.isbn)
            let isbnKey = normalizedISBN(isbnRaw)
            let taKey = titleAuthorKey(title: title, author: author)

            let isDuplicate = (!isbnKey.isEmpty && seenISBNs.contains(isbnKey))
                || seenTitleAuthors.contains(taKey)
            if isDuplicate {
                duplicates += 1
                continue
            }
            if !isbnKey.isEmpty { seenISBNs.insert(isbnKey) }
            seenTitleAuthors.insert(taKey)

            toAdd.append(
                Book(
                    title: title,
                    author: author,
                    isbn: isbnRaw,
                    bookDescription: trimmed(incoming.bookDescription),
                    genre: trimmed(incoming.genre),
                    rating: min(max(incoming.rating ?? 0, 0), 5),
                    goodreadsURL: trimmed(incoming.goodreadsURL),
                    amazonURL: trimmed(incoming.amazonURL),
                    coverImageURL: trimmed(incoming.coverImageURL),
                    note: trimmed(incoming.note),
                    tags: (incoming.tags ?? [])
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                )
            )
        }

        return Result(toAdd: toAdd, duplicateCount: duplicates)
    }

    /// Minimal shape used to read the version before committing to the full
    /// decode.
    private struct VersionProbe: Decodable {
        var schemaVersion: Int
    }

    private static func trimmed(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Reduces an ISBN to just its significant characters so formatting
    /// differences (hyphens, spaces, lowercase check digit) don't defeat
    /// duplicate detection. Returns "" when there's nothing usable.
    private static func normalizedISBN(_ value: String) -> String {
        value.uppercased().filter { $0.isNumber || $0 == "X" }
    }

    private static func titleAuthorKey(title: String, author: String) -> String {
        "\(title.lowercased())|\(author.lowercased())"
    }
}
