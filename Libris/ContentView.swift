//
//  ContentView.swift
//  Libris
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // Fetch every book and filter in memory. A personal library is small, and
    // in-memory filtering keeps the CloudKit-backed store simple and robust.
    @Query(sort: [SortDescriptor(\Book.title), SortDescriptor(\Book.dateAdded)])
    private var books: [Book]

    @State private var searchText = ""
    @State private var statusFilter: BookStatus? = nil
    @State private var genreFilter: String? = nil
    @State private var showingImportBooks = false

    // Drives the editing sheet: which existing book is being edited (nil = none).
    @State private var editingBook: Book? = nil
    // Drives the editing sheet for a brand-new book that isn't inserted into the
    // store until the user taps Done.
    @State private var newBook: Book? = nil

    // The book awaiting delete confirmation (nil = no confirmation showing).
    @State private var bookToDelete: Book? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FilterBarView(
                    searchText: $searchText,
                    statusFilter: $statusFilter,
                    genreFilter: $genreFilter,
                    availableGenres: availableGenres
                )
                Divider()
                CountsBarView(
                    books: books,
                    filteredCount: filteredBooks.count,
                    isFiltering: isFiltering
                )
                Divider()
                BookGridView(
                    books: filteredBooks,
                    libraryIsEmpty: books.isEmpty,
                    onEdit: { editingBook = $0 },
                    onDelete: { bookToDelete = $0 },
                    onLoadSample: loadSampleBooks
                )
            }
            .navigationTitle("Libris")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        addBook()
                    } label: {
                        Label("New Book", systemImage: "plus")
                    }
                    .help("Add a single empty book")

                    Button {
                        showingImportBooks = true
                    } label: {
                        Label("Import Books", systemImage: "square.and.arrow.down.on.square")
                    }
                    .help("Add books")
                }
            }
            .sheet(item: $editingBook) { book in
                BookEditorView(
                    book: book,
                    navigationTitle: "Edit Book",
                    onCancel: { editingBook = nil },
                    onSave: { editingBook = nil }
                )
            }
            .sheet(item: $newBook) { book in
                BookEditorView(
                    book: book,
                    navigationTitle: "New Book",
                    onCancel: { newBook = nil },
                    onSave: {
                        modelContext.insert(book)
                        newBook = nil
                    }
                )
            }
            .alert(deleteAlertTitle, isPresented: showingDeleteConfirmation, presenting: bookToDelete) { book in
                Button("Delete", role: .destructive) {
                    deleteBook(book)
                }
                Button("Cancel", role: .cancel) { }
            } message: { _ in
                Text("This can’t be undone.")
            }
            .onChange(of: availableGenres) { _, genres in
                if let genreFilter, !genres.contains(genreFilter) {
                    self.genreFilter = nil
                }
            }
        }
        .frame(minWidth: 640, minHeight: 480)
    }

    // MARK: - Derived data

    private var availableGenres: [String] {
        let genres = Set(books.map(\.genre).filter { !$0.isEmpty })
        return genres.sorted()
    }

    private var isFiltering: Bool {
        !searchText.isEmpty || statusFilter != nil || genreFilter != nil
    }

    /// Bridges the optional `bookToDelete` to the alert's `isPresented`, clearing
    /// the pending book when the alert is dismissed.
    private var showingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { bookToDelete != nil },
            set: { if !$0 { bookToDelete = nil } }
        )
    }

    private var deleteAlertTitle: String {
        guard let book = bookToDelete else { return "Delete this book?" }
        let title = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Delete this book?" : "Delete “\(title)”?"
    }

    private var filteredBooks: [Book] {
        BookFilter.filter(books, searchText: searchText, status: statusFilter, genre: genreFilter)
    }

    // MARK: - Mutations

    private func addBook() {
        // Open the editor on a fresh book; it isn't inserted until the user
        // taps Done, so cancelling leaves the library untouched.
        newBook = Book(title: "", author: "")
    }

    private func deleteBook(_ book: Book) {
        withAnimation {
            modelContext.delete(book)
        }
    }

    /// Inserts the built-in sample books. Triggered explicitly from the empty
    /// state, so it never runs on its own and can't duplicate a synced library.
    private func loadSampleBooks() {
        withAnimation {
            for book in SampleData.makeBooks() {
                modelContext.insert(book)
            }
        }
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
