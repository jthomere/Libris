//
//  ContentView.swift
//  Libris
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // Fetch every book and filter in memory. A personal library is small, and
    // in-memory filtering keeps the CloudKit-backed store simple and robust.
    @Query(sort: [SortDescriptor(\Book.title), SortDescriptor(\Book.dateAdded)])
    private var books: [Book]

    @State private var searchText = ""
    @State private var statusFilter: BookStatus? = nil
    @State private var genreFilter: String? = nil
    // Whether to hide books marked To Remove from the default ("All Statuses")
    // view. On by default so those books stay out of the way until wanted.
    @State private var hideToRemove = true
    @State private var showingImportBooks = false

    // Drives the post-import result alert (success summary or failure).
    @State private var importAlert: ImportAlert? = nil

    // Drives the editing sheet: which existing book is being edited (nil = none).
    @State private var editingBook: Book? = nil
    // Drives the editing sheet for a brand-new book that isn't inserted into the
    // store until the user taps Done.
    @State private var newBook: Book? = nil

    // The book awaiting delete confirmation (nil = no confirmation showing).
    @State private var bookToDelete: Book? = nil

    // Drives the confirmation for permanently deleting every To Remove book.
    @State private var confirmingDeleteToRemove = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FilterBarView(
                    searchText: $searchText,
                    genreFilter: $genreFilter,
                    availableGenres: availableGenres
                )
                Divider()
                CountsBarView(
                    books: books,
                    statusFilter: $statusFilter,
                    hideToRemove: $hideToRemove
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

                    if statusFilter == .toRemove {
                        Button(role: .destructive) {
                            confirmingDeleteToRemove = true
                        } label: {
                            Label("Delete All…", systemImage: "trash")
                        }
                        .help("Permanently delete every book marked To Remove")
                        .disabled(toRemoveBooks.isEmpty)
                    }
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
            .fileImporter(
                isPresented: $showingImportBooks,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert(deleteAlertTitle, isPresented: showingDeleteConfirmation, presenting: bookToDelete) { book in
                Button("Delete", role: .destructive) {
                    deleteBook(book)
                }
                Button("Cancel", role: .cancel) { }
            } message: { _ in
                Text("This can’t be undone.")
            }
            .alert("Delete Books to Remove?", isPresented: $confirmingDeleteToRemove) {
                Button("Delete", role: .destructive) {
                    deleteAllToRemove()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                let count = toRemoveBooks.count
                Text("This permanently deletes \(count) book\(count == 1 ? "" : "s") marked To Remove. This can’t be undone.")
            }
            .alert(importAlert?.title ?? "", isPresented: showingImportAlert, presenting: importAlert) { _ in
                Button("OK", role: .cancel) { }
            } message: { alert in
                Text(alert.message)
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

    private var toRemoveBooks: [Book] {
        books.filter { $0.status == .toRemove }
    }

    /// Bridges the optional `bookToDelete` to the alert's `isPresented`, clearing
    /// the pending book when the alert is dismissed.
    private var showingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { bookToDelete != nil },
            set: { if !$0 { bookToDelete = nil } }
        )
    }

    /// Bridges the optional `importAlert` to the alert's `isPresented`, clearing
    /// it when the alert is dismissed.
    private var showingImportAlert: Binding<Bool> {
        Binding(
            get: { importAlert != nil },
            set: { if !$0 { importAlert = nil } }
        )
    }

    private var deleteAlertTitle: String {
        guard let book = bookToDelete else { return "Delete this book?" }
        let title = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Delete this book?" : "Delete “\(title)”?"
    }

    private var filteredBooks: [Book] {
        BookFilter.filter(books, searchText: searchText, status: statusFilter, genre: genreFilter, hideToRemove: hideToRemove)
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

    /// Permanently deletes every book marked To Remove.
    private func deleteAllToRemove() {
        withAnimation {
            for book in toRemoveBooks {
                modelContext.delete(book)
            }
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

    // MARK: - Import

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importBooks(from: url)
        case .failure(let error):
            importAlert = .failure(message: error.localizedDescription)
        }
    }

    /// Reads the chosen file, adds the non-duplicate books, and reports the
    /// outcome. Existing books are never touched; duplicates are skipped in
    /// `ImportParser`.
    private func importBooks(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let parsed = try ImportParser.parse(data, existingBooks: books)
            withAnimation {
                for book in parsed.toAdd {
                    modelContext.insert(book)
                }
            }
            importAlert = .summary(added: parsed.toAdd.count, duplicates: parsed.duplicateCount)
        } catch let error as ImportParser.ImportError {
            importAlert = .failure(message: error.errorDescription ?? "The file couldn’t be imported.")
        } catch {
            importAlert = .failure(message: error.localizedDescription)
        }
    }

    private enum ImportAlert: Identifiable {
        case summary(added: Int, duplicates: Int)
        case failure(message: String)

        var id: String {
            switch self {
            case .summary(let added, let duplicates): return "summary-\(added)-\(duplicates)"
            case .failure(let message): return "failure-\(message)"
            }
        }

        var title: String {
            switch self {
            case .summary(let added, _): return added == 0 ? "No New Books" : "Books Imported"
            case .failure: return "Import Failed"
            }
        }

        var message: String {
            switch self {
            case .summary(let added, let duplicates):
                var parts = [added == 1 ? "Added 1 book." : "Added \(added) books."]
                if duplicates > 0 {
                    parts.append(duplicates == 1
                        ? "Skipped 1 duplicate."
                        : "Skipped \(duplicates) duplicates.")
                }
                return parts.joined(separator: " ")
            case .failure(let message):
                return message
            }
        }
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
