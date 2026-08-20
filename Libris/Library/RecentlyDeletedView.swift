//
//  RecentlyDeletedView.swift
//  Libris
//
//  The trash: books that have been deleted from the library but not yet
//  permanently removed. Presented as a sheet so its restore/permanent-delete
//  actions stay separate from the library's status and edit actions.
//

import SwiftUI
import SwiftData

struct RecentlyDeletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // The trash's own live fetch: newest deletions first. Kept separate from
    // ContentView so the sheet updates itself as books are restored or purged.
    @Query(RecentlyDeletedView.trashDescriptor)
    private var deletedBooks: [Book]

    // Built as a FetchDescriptor rather than inline `@Query(filter:sort:)` to
    // keep the predicate-plus-sort expression within the type-checker's reach.
    private static var trashDescriptor: FetchDescriptor<Book> {
        FetchDescriptor<Book>(
            predicate: #Predicate { $0.deletedDate != nil },
            sortBy: [SortDescriptor(\.deletedDate, order: .reverse)]
        )
    }

    // The book awaiting permanent-delete confirmation (nil = none).
    @State private var bookToPurge: Book? = nil
    // Drives the Empty Trash confirmation.
    @State private var confirmingEmptyTrash = false

    var body: some View {
        NavigationStack {
            Group {
                if deletedBooks.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Recently Deleted")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        confirmingEmptyTrash = true
                    } label: {
                        Label("Empty Trash", systemImage: "trash")
                    }
                    .help("Permanently delete every book in the trash")
                    .disabled(deletedBooks.isEmpty)
                }
            }
            .alert(purgeAlertTitle, isPresented: $bookToPurge.isPresent(), presenting: bookToPurge) { book in
                Button("Delete Permanently", role: .destructive) {
                    purge(book)
                }
                Button("Cancel", role: .cancel) { }
            } message: { _ in
                Text("This can’t be undone.")
            }
            .alert("Empty Trash?", isPresented: $confirmingEmptyTrash) {
                Button("Delete Permanently", role: .destructive) {
                    emptyTrash()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                let count = deletedBooks.count
                Text("This permanently deletes \(count) book\(count == 1 ? "" : "s") in the trash. This can’t be undone.")
            }
        }
        .frame(minWidth: 480, minHeight: 420)
    }

    // MARK: - Content

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(deletedBooks.enumerated()), id: \.element.id) { index, book in
                    row(book)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    if index < deletedBooks.count - 1 {
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
                restore(book)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .help("Move this book back to the library")

            Button(role: .destructive) {
                bookToPurge = book
            } label: {
                Label("Delete Permanently", systemImage: "trash")
            }
            .help("Remove this book for good")
        }
    }

    @ViewBuilder
    private func cover(_ book: Book) -> some View {
        if let url = URLNormalizer.normalized(from: book.coverImageURL) {
            CachedCoverImage(url: url)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Trash is Empty", systemImage: "trash")
        } description: {
            Text("Books you delete appear here, where you can restore them or remove them for good.")
        }
    }

    private var purgeAlertTitle: String {
        guard let book = bookToPurge else { return "Delete this book permanently?" }
        let title = book.title.whitespaceTrimmed
        return title.isEmpty ? "Delete this book permanently?" : "Delete “\(title)” permanently?"
    }

    // MARK: - Mutations

    /// Moves the book back to the library.
    private func restore(_ book: Book) {
        withAnimation {
            book.deletedDate = nil
        }
    }

    /// Permanently removes the book from the store.
    private func purge(_ book: Book) {
        withAnimation {
            modelContext.delete(book)
        }
    }

    /// Permanently removes every book in the trash.
    private func emptyTrash() {
        withAnimation {
            for book in deletedBooks {
                modelContext.delete(book)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Book.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let now = Date()
    container.mainContext.insert(Book(title: "Old Manual", author: "Anon", status: .toRemove, deletedDate: now))
    container.mainContext.insert(Book(title: "Dune", author: "Frank Herbert", deletedDate: now.addingTimeInterval(-86_400 * 3)))
    return RecentlyDeletedView()
        .modelContainer(container)
}
