//
//  BatchImportParser.swift
//  Libris
//
//  Parses the pasted text used by BatchImportView into books to add, skipping
//  blank lines and any book whose title+author already exists in the library
//  or earlier in the paste. Kept separate from the view so it can be tested
//  directly.
//

import Foundation

enum BatchImportParser {
    struct Result {
        var toAdd: [Book]
        var duplicateCount: Int
    }

    /// Parses `text`, skipping blank lines and any book whose title+author
    /// already exists in `existingBooks` or earlier in the paste.
    static func parse(_ text: String, existingBooks: [Book]) -> Result {
        var seen = Set(existingBooks.map { dedupeKey(title: $0.title, author: $0.author) })

        var toAdd: [Book] = []
        var duplicates = 0

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            let fields = line.components(separatedBy: "|").map {
                $0.trimmingCharacters(in: .whitespaces)
            }

            let title = fields.first ?? ""
            guard !title.isEmpty else { continue }

            let author = fields.count > 1 ? fields[1] : ""
            let genre = fields.count > 2 ? fields[2] : ""
            let rating = fields.count > 3 ? (Double(fields[3]) ?? 0) : 0
            let tags: [String] = fields.count > 4
                ? fields[4].split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                : []

            let key = dedupeKey(title: title, author: author)
            if seen.contains(key) {
                duplicates += 1
                continue
            }
            seen.insert(key)

            toAdd.append(
                Book(
                    title: title,
                    author: author,
                    genre: genre,
                    rating: min(max(rating, 0), 5),
                    tags: tags
                )
            )
        }

        return Result(toAdd: toAdd, duplicateCount: duplicates)
    }

    private static func dedupeKey(title: String, author: String) -> String {
        "\(title.lowercased())|\(author.lowercased())"
    }
}
