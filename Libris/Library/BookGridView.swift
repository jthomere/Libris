//
//  BookGridView.swift
//  Libris
//

import SwiftUI

enum LibraryCardStyle: String, CaseIterable {
    case full
    case mini
}

struct BookGridView: View {
    /// The sections to display (already filtered and sorted by the caller).
    let sections: [BookSection]
    /// Whether the underlying library is empty, distinguishing "no books yet"
    /// from "no matches for the current filters".
    let libraryIsEmpty: Bool
    let style: LibraryCardStyle
    let onEdit: (Book) -> Void
    let onDelete: (Book) -> Void
    /// Moves every currently-visible book to the Trash.
    let onDeleteAllVisible: () -> Void

    private var columns: [GridItem] {
        switch style {
        case .full: [GridItem(.adaptive(minimum: 360, maximum: 420), spacing: 16, alignment: .top)]
        case .mini: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16, alignment: .top)]
        }
    }

    private var totalCount: Int {
        sections.reduce(0) { $0 + $1.books.count }
    }

    var body: some View {
        ScrollView {
            if sections.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.books) { book in
                                card(for: book)
                            }
                        } header: {
                            sectionHeader(section.title)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !sections.isEmpty {
                bottomBar
            }
        }
    }

    @ViewBuilder
    private func card(for book: Book) -> some View {
        switch style {
        case .full:
            BookCardView(
                book: book,
                onEdit: { onEdit(book) },
                onDelete: { onDelete(book) }
            )
        case .mini:
            BookMiniCardView(
                book: book,
                onEdit: { onEdit(book) },
                onDelete: { onDelete(book) }
            )
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    /// A pinned footer showing how many books are visible, with a control to
    /// move the whole visible set to the Trash at once.
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Spacer()
                Text("\(totalCount) shown")
                    .foregroundStyle(.secondary)
                Button(role: .destructive, action: onDeleteAllVisible) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete all visible books")
                .help("Move all \(totalCount) visible book\(totalCount == 1 ? "" : "s") to the Trash")
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
