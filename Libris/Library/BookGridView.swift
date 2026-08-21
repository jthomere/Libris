//
//  BookGridView.swift
//  Libris
//

import SwiftUI

struct BookGridView: View {
    /// The books to display (already filtered by the caller).
    let books: [Book]
    /// Whether the underlying library is empty, distinguishing "no books yet"
    /// from "no matches for the current filters".
    let libraryIsEmpty: Bool
    let onEdit: (Book) -> Void
    let onDelete: (Book) -> Void
    /// Moves every currently-visible book to the Trash.
    let onDeleteAllVisible: () -> Void

    // Adaptive grid of book cards.
    private let columns = [GridItem(.adaptive(minimum: 440, maximum: 600), spacing: 16)]

    var body: some View {
        ScrollView {
            if books.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(books) { book in
                        BookCardView(
                            book: book,
                            onEdit: { onEdit(book) },
                            onDelete: { onDelete(book) }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !books.isEmpty {
                bottomBar
            }
        }
    }

    /// A pinned footer showing how many books are visible, with a control to
    /// move the whole visible set to the Trash at once.
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Spacer()
                Text("\(books.count) shown")
                    .foregroundStyle(.secondary)
                Button(role: .destructive, action: onDeleteAllVisible) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete all visible books")
                .help("Move all \(books.count) visible book\(books.count == 1 ? "" : "s") to the Trash")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    /// Shown when there are no books to display, distinguishing an empty
    /// library from filters that match nothing.
    private var emptyState: some View {
        ContentUnavailableView {
            Label(libraryIsEmpty ? "No Books Yet" : "No Matches",
                  systemImage: "books.vertical")
        } description: {
            Text(libraryIsEmpty
                 ? "Add a book or import a batch to get started."
                 : "Try adjusting your search or filters.")
        }
        .padding(.top, 60)
    }
}
