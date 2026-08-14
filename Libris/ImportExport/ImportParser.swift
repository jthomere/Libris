//
//  ImportParser.swift
//  Libris
//
//  Turns the raw bytes of a library file into books to add, skipping any book
//  that already exists in the library or earlier in the file. A book is a
//  duplicate if its ISBN (when present) or its title+author matches. Existing
//  books are never touched. Kept separate from the UI so it can be tested.
//

import Foundation

enum ImportParser {
    /// The version written into files this build exports.
    static let latestVersion = 2

    /// Every version this build can read: legacy version-1 import files and
    /// the version-2 backup shape that also carries kind, status, and dateAdded.
    static let supportedVersions: Set<Int> = [1, 2]

    struct Result {
        var toAdd: [Book]
        var duplicateCount: Int
        var isBackup: Bool

        /// Books the file held before duplicates were skipped.
        var fileBookCount: Int { toAdd.count + duplicateCount }
    }

    enum ImportError: LocalizedError {
        case invalidFile
        case unsupportedVersion(Int)

        var errorDescription: String? {
            switch self {
            case .invalidFile:
                return "This file isn’t a valid Libris library file."
            case .unsupportedVersion(let version):
                return "This file uses format version \(version), which this version of Libris doesn’t support. Update Libris and try again."
            }
        }
    }

    static func parse(_ data: Data, existingBooks: [Book]) throws -> Result {
        let file = try decodeLibraryFile(from: data)
        let isBackup = file.kind == LibraryFile.backupKind

        var tracker = DuplicateTracker(existingBooks: existingBooks)
        var toAdd: [Book] = []
        var duplicateCount = 0

        for incomingRecord in file.records {
            let title = trimmed(incomingRecord.title)
            // A backup restores its books verbatim, including any saved with a
            // blank title; a plain add-list rejects those as junk. Blank titles
            // can't be told apart by title+author, so they skip that dedup and
            // only an ISBN match can flag them.
            if title.isEmpty && !isBackup { continue }
            let author = trimmed(incomingRecord.author)
            let isbn = trimmed(incomingRecord.isbn)

            if tracker.isDuplicate(title: title, author: author, isbn: isbn) {
                duplicateCount += 1
                continue
            }
            tracker.remember(title: title, author: author, isbn: isbn)
            toAdd.append(makeBook(from: incomingRecord))
        }

        return Result(toAdd: toAdd, duplicateCount: duplicateCount, isBackup: isBackup)
    }

    /// Decodes the file after confirming its version, so a newer file reports an
    /// unsupported version rather than a confusing parse failure.
    private static func decodeLibraryFile(from data: Data) throws -> LibraryFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = LibraryDateCoding.decoding

        guard let probe = try? decoder.decode(VersionProbe.self, from: data) else {
            throw ImportError.invalidFile
        }
        guard supportedVersions.contains(probe.schemaVersion) else {
            throw ImportError.unsupportedVersion(probe.schemaVersion)
        }
        guard let file = try? decoder.decode(LibraryFile.self, from: data) else {
            throw ImportError.invalidFile
        }
        return file
    }

    /// Builds a `Book` from an incoming record, trimming its text and clamping
    /// its rating to the 0...5 the UI expects.
    private static func makeBook(from record: BookRecord) -> Book {
        Book(
            title: trimmed(record.title),
            author: trimmed(record.author),
            isbn: trimmed(record.isbn),
            bookDescription: trimmed(record.bookDescription),
            genre: trimmed(record.genre),
            rating: min(max(record.rating ?? 0, 0), 5),
            goodreadsURL: trimmed(record.goodreadsURL),
            amazonURL: trimmed(record.amazonURL),
            coverImageURL: trimmed(record.coverImageURL),
            note: trimmed(record.note),
            tags: normalizedTags(record.tags),
            status: status(from: record.status),
            dateAdded: record.dateAdded ?? Date()
        )
    }

    private struct VersionProbe: Decodable {
        var schemaVersion: Int
    }

    private static func trimmed(_ value: String?) -> String {
        (value ?? "").whitespaceTrimmed
    }

    private static func status(from raw: String?) -> BookStatus {
        guard let raw else { return .unsorted }
        return BookStatus(rawValue: raw.whitespaceTrimmed) ?? .unsorted
    }

    private static func normalizedTags(_ tags: [String]?) -> [String] {
        (tags ?? [])
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
