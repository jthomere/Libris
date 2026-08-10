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
    @State private var showingBatchImport = false

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
                    onDelete: deleteBook,
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
                        showingBatchImport = true
                    } label: {
                        Label("Import Batch", systemImage: "square.and.arrow.down.on.square")
                    }
                    .help("Add a batch of books from pasted text")
                }
            }
            .sheet(isPresented: $showingBatchImport) {
                BatchImportView(existingBooks: books) { newBooks in
                    importBooks(newBooks)
                }
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

    private var filteredBooks: [Book] {
        BookFilter.filter(books, searchText: searchText, status: statusFilter, genre: genreFilter)
    }

    // MARK: - Mutations

    private func addBook() {
        let book = Book(title: "", author: "")
        modelContext.insert(book)
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

    /// Inserts newly created books. Existing books are never touched, so this
    /// can't overwrite or corrupt the current library. Duplicate detection
    /// happens in `BatchImportView` before this is called.
    private func importBooks(_ newBooks: [Book]) {
        withAnimation {
            for book in newBooks {
                modelContext.insert(book)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
