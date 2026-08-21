//
//  RecentlyDeletedView.swift
//  Libris
//
//  The trash: books that have been deleted from the library but not yet
//  permanently removed. A pure presentation view — it displays the books it's
//  given and reports actions back through closures; the owner holds the data.
//

import SwiftUI

struct RecentlyDeletedView: View {
    /// The trashed books to display, newest deletions first (ordered by caller).
    let books: [Book]
    var onRestore: (Book) -> Void
    var onDeletePermanently: (Book) -> Void
    var onEmptyTrash: () -> Void

    @Environment(\.dismiss) private var dismiss

    // The book awaiting permanent-delete confirmation (nil = none).
    @State private var bookToPurge: Book? = nil
    // Drives the Empty Trash confirmation.
    @State private var confirmingEmptyTrash = false

    var body: some View {
        // A fixed header and bottom bar with only the list between them (à la
        // Finder's Trash), so restoring the last book empties the pane without
        // any chrome shifting.
        VStack(spacing: 0) {
            header
            Divider()
            list
            Divider()
            bottomBar
        }
        .frame(minWidth: 480, minHeight: 420)
        .alert(purgeAlertTitle, isPresented: $bookToPurge.isPresent(), presenting: bookToPurge) { book in
            Button("Delete Permanently", role: .destructive) {
                onDeletePermanently(book)
            }
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("This can’t be undone.")
        }
        .alert("Empty Trash?", isPresented: $confirmingEmptyTrash) {
            Button("Delete Permanently", role: .destructive) {
                onEmptyTrash()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            let count = books.count
            Text("This permanently deletes \(count) book\(count == 1 ? "" : "s") in the trash. This can’t be undone.")
        }
    }

    // MARK: - Chrome

    private var header: some View {
        Text("Recently Deleted")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                confirmingEmptyTrash = true
            } label: {
                Label("Empty Trash", systemImage: "trash")
            }
            .help("Permanently delete every book in the trash")
            .disabled(books.isEmpty)

            Spacer()

            Text("\(books.count) book\(books.count == 1 ? "" : "s")")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Done") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Content

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                    row(book)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    if index < books.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func row(_ book: Book) -> some View {
        HStack(alignment: .center, spacing: 12) {
            cover(book)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title.isEmpty ? "Untitled" : book.title)
                    .font(.headline)
                    .foregroundStyle(book.title.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                Text(book.author.isEmpty ? "Unknown author" : book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let deletedDate = book.deletedDate {
                    Text("Deleted \(deletedDate, format: .relative(presentation: .numeric))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            Button {
                onRestore(book)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .help("Move this book back to the library")
            .fixedSize()

            Button(role: .destructive) {
                bookToPurge = book
            } label: {
                Label("Delete Permanently", systemImage: "trash")
            }
            .help("Remove this book for good")
            .fixedSize()
        }
    }

    @ViewBuilder
    private func cover(_ book: Book) -> some View {
        if let url = URLNormalizer.normalized(from: book.coverImageURL) {
            CachedCoverImage(url: url)
        }
    }

    private var purgeAlertTitle: String {
        guard let book = bookToPurge else { return "Delete this book permanently?" }
        let title = book.title.whitespaceTrimmed
        return title.isEmpty ? "Delete this book permanently?" : "Delete “\(title)” permanently?"
    }
}

#Preview("With books") {
    let now = Date()
    return RecentlyDeletedView(
        books: [
            Book(title: "Old Manual", author: "Anon", status: .notInterested, deletedDate: now),
            Book(title: "Dune", author: "Frank Herbert", deletedDate: now.addingTimeInterval(-86_400 * 3))
        ],
        onRestore: { _ in },
        onDeletePermanently: { _ in },
        onEmptyTrash: { }
    )
}

#Preview("Empty") {
    RecentlyDeletedView(
        books: [],
        onRestore: { _ in },
        onDeletePermanently: { _ in },
        onEmptyTrash: { }
    )
}
