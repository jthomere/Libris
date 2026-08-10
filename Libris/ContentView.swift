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

    // Adaptive grid of book cards.
    private let columns = [GridItem(.adaptive(minimum: 360, maximum: 520), spacing: 16)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                Divider()
                countsBar
                Divider()
                bookGrid
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
        }
        .frame(minWidth: 640, minHeight: 480)
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search title or author", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 320)

            Picker("Status", selection: $statusFilter) {
                Text("All Statuses").tag(BookStatus?.none)
                ForEach(BookStatus.allCases) { status in
                    Text(status.label).tag(BookStatus?.some(status))
                }
            }
            .frame(maxWidth: 180)

            Picker("Genre", selection: $genreFilter) {
                Text("All Genres").tag(String?.none)
                ForEach(availableGenres, id: \.self) { genre in
                    Text(genre).tag(String?.some(genre))
                }
            }
            .frame(maxWidth: 180)

            Spacer()
        }
        .padding(12)
    }

    // MARK: - Counts bar

    private var countsBar: some View {
        HStack(spacing: 10) {
            countChip(label: "Total", count: books.count, image: "books.vertical")
            ForEach(BookStatus.allCases) { status in
                countChip(
                    label: status.label,
                    count: count(for: status),
                    image: status.systemImage
                )
            }
            Spacer()
            if isFiltering {
                Text("\(filteredBooks.count) shown")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func countChip(label: String, count: Int, image: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: image)
            Text(label)
            Text("\(count)")
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.callout)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.quaternary, in: Capsule())
    }

    // MARK: - Grid

    private var bookGrid: some View {
        ScrollView {
            if filteredBooks.isEmpty {
                ContentUnavailableView {
                    Label(books.isEmpty ? "No Books Yet" : "No Matches",
                          systemImage: "books.vertical")
                } description: {
                    Text(books.isEmpty
                         ? "Add a book or import a batch to get started."
                         : "Try adjusting your search or filters.")
                } actions: {
                    if books.isEmpty {
                        Button("Load Sample Books") {
                            loadSampleBooks()
                        }
                    }
                }
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(filteredBooks) { book in
                        BookCardView(book: book) {
                            deleteBook(book)
                        }
                    }
                }
                .padding(16)
            }
        }
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
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return books.filter { book in
            if let statusFilter, book.status != statusFilter { return false }
            if let genreFilter, book.genre != genreFilter { return false }
            if !query.isEmpty {
                let matchesTitle = book.title.lowercased().contains(query)
                let matchesAuthor = book.author.lowercased().contains(query)
                if !matchesTitle && !matchesAuthor { return false }
            }
            return true
        }
    }

    private func count(for status: BookStatus) -> Int {
        books.filter { $0.status == status }.count
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
