//
//  BatchImportView.swift
//  Libris
//
//  Adds a batch of books from pasted text. Books that already exist (matched
//  by title + author) are skipped, so importing can never duplicate, overwrite,
//  or corrupt the books already in the library.
//

import SwiftUI

struct BatchImportView: View {
    /// The current library, used to detect and skip duplicates.
    let existingBooks: [Book]
    /// Called with the freshly built (not-yet-inserted) books to add.
    var onImport: ([Book]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pastedText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Books")
                .font(.title2.bold())

            Text("Paste one book per line. Separate fields with a vertical bar `|` in this order:")
                .foregroundStyle(.secondary)
            Text("Title | Author | Genre | Rating | Tags")
                .font(.system(.callout, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            Text("Only the title is required. Separate multiple tags with semicolons.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $pastedText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 180)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary, lineWidth: 1))

            summary

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add \(parsed.toAdd.count) Books") {
                    onImport(parsed.toAdd)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(parsed.toAdd.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 560)
    }

    private var summary: some View {
        HStack(spacing: 16) {
            Label("\(parsed.toAdd.count) to add", systemImage: "plus.circle")
                .foregroundStyle(.green)
            if parsed.duplicateCount > 0 {
                Label("\(parsed.duplicateCount) duplicate\(parsed.duplicateCount == 1 ? "" : "s") skipped",
                      systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
        .font(.callout)
    }

    // MARK: - Parsing

    private struct ParseResult {
        var toAdd: [Book]
        var duplicateCount: Int
    }

    /// Parses the pasted text, skipping blank lines and any book whose
    /// title+author already exists in the library or earlier in the paste.
    private var parsed: ParseResult {
        var seen = Set(existingBooks.map { dedupeKey(title: $0.title, author: $0.author) })

        var toAdd: [Book] = []
        var duplicates = 0

        for rawLine in pastedText.split(separator: "\n", omittingEmptySubsequences: false) {
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

        return ParseResult(toAdd: toAdd, duplicateCount: duplicates)
    }

    private func dedupeKey(title: String, author: String) -> String {
        "\(title.lowercased())|\(author.lowercased())"
    }
}
