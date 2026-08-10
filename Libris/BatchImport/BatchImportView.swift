//
//  BatchImportView.swift
//  Libris
//
//  Adds a batch of books from pasted text. Books that already exist (matched
//  by title + author) are skipped, so importing can never duplicate, overwrite,
//  or corrupt the books already in the library. Parsing lives in
//  `BatchImportParser`.
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

    private var parsed: BatchImportParser.Result {
        BatchImportParser.parse(pastedText, existingBooks: existingBooks)
    }
}
