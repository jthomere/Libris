//
//  ContentView.swift
//  Libris
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // Fetch every book still in the library (deleted books are excluded at the
    // fetch, so every derived view below sees only active books) and filter in
    // memory. A personal library is small, and in-memory filtering keeps the
    // CloudKit-backed store simple and robust.
    @Query(ContentView.activeBooksDescriptor)
    private var books: [Book]

    // The deleted books, used only for the toolbar's Recently Deleted button
    // (its count and enabled state). The Trash sheet fetches its own copy.
    @Query(filter: #Predicate<Book> { $0.deletedDate != nil })
    private var deletedBooks: [Book]

    // Built as a FetchDescriptor rather than inline `@Query(filter:sort:)` to
    // keep the predicate-plus-sort expression within the type-checker's reach.
    private static var activeBooksDescriptor: FetchDescriptor<Book> {
        FetchDescriptor<Book>(
            predicate: #Predicate { $0.deletedDate == nil },
            sortBy: [SortDescriptor(\.title), SortDescriptor(\.dateAdded)]
        )
    }

    @State private var searchText = ""
    @State private var genreFilter: String? = nil
    // The statuses currently shown. Defaults to every status except Not
    // Interested, so those books stay out of the way until the user opts in.
    @State private var visibleStatuses: Set<BookStatus> = StatusPreset.default.statuses
    @State private var showingImportBooks = false
    @State private var showingImportPrompt = false

    // Drives the export save panel and the document handed to it.
    @State private var showingExport = false
    @State private var exportDocument = ExportDocument(data: Data())

    // Drives the post-import result alert (success summary or failure).
    @State private var importAlert: ImportAlert? = nil

    // A parsed backup awaiting confirmation before merging (nil = none).
    @State private var pendingBackup: ImportParser.Result? = nil

    // A failed export's message (nil = no error showing).
    @State private var exportError: String? = nil

    // Drives the editing sheet: which existing book is being edited (nil = none).
    @State private var editingBook: Book? = nil
    // Drives the editing sheet for a brand-new book that isn't inserted into the
    // store until the user taps Done.
    @State private var newBook: Book? = nil

    // A brief, self-dismissing message shown after a delete (nil = none). Its
    // id changes on each delete so repeated deletes re-trigger the timer.
    @State private var deletionToast: DeletionToast? = nil

    @State private var showingRecentlyAdded = false

    // Drives the Recently Deleted (trash) sheet.
    @State private var showingTrash = false

    // Drives the confirmation for moving every currently-visible book to the Trash.
    @State private var confirmingDeleteAllVisible = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FilterBarView(
                    searchText: $searchText,
                    genreFilter: $genreFilter,
                    availableGenres: availableGenres,
                    showingRecentlyAdded: $showingRecentlyAdded,
                    recentlyAddedCount: mostRecentlyAdded.count
                )
                Divider()
                StatusFilterView(
                    books: books,
                    visibleStatuses: $visibleStatuses
                )
                Divider()
                BookGridView(
                    books: filteredBooks,
                    libraryIsEmpty: books.isEmpty,
                    onEdit: { editingBook = $0 },
                    onDelete: { deleteBook($0) },
                    onDeleteAllVisible: { confirmingDeleteAllVisible = true }
                )
            }
            .overlay(alignment: .bottom) {
                if let deletionToast {
                    Text(deletionToast.message)
                        .font(.title3)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(.separator))
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                        .padding(.bottom, 28)
                }
            }
            .task(id: deletionToast?.id) {
                guard deletionToast != nil else { return }
                try? await Task.sleep(for: .seconds(2))
                deletionToast = nil
            }
            .navigationTitle("Libris")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        showingImportPrompt = true
                    } label: {
                        Label("AI Prompt", systemImage: "sparkles")
                    }
                    .help("Copy a prompt for an AI assistant to build an import file")

                    Button {
                        showingImportBooks = true
                    } label: {
                        Label("Import Books", systemImage: "square.and.arrow.down.on.square")
                    }
                    .help("Add books")

                    Button {
                        addBook()
                    } label: {
                        Label("New Book", systemImage: "plus")
                    }
                    .help("Add a single empty book")

                    Button {
                        prepareExport()
                    } label: {
                        Label("Export Library", systemImage: "square.and.arrow.up.on.square")
                    }
                    .help("Save every book to a file, for backup")
                    .disabled(books.isEmpty)

                    Button {
                        showingTrash = true
                    } label: {
                        Label("Recently Deleted", systemImage: "trash")
                    }
                    .help("Show deleted books, to restore or permanently delete them")
                    .disabled(deletedBooks.isEmpty)
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
            .sheet(isPresented: $showingImportPrompt) {
                AIPromptView(genres: availableGenres, tags: availableTags)
            }
            .sheet(isPresented: $showingTrash) {
                RecentlyDeletedView()
            }
            .fileExporter(
                isPresented: $showingExport,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFilename
            ) { result in
                handleExport(result)
            }
            .alert("Delete All Visible Books?", isPresented: $confirmingDeleteAllVisible) {
                Button("Delete", role: .destructive) {
                    deleteAllVisible()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                let count = filteredBooks.count
                Text("This moves \(count) book\(count == 1 ? "" : "s") to the Trash. You can restore \(count == 1 ? "it" : "them") from Recently Deleted.")
            }
            .alert("Import this backup?", isPresented: $pendingBackup.isPresent(), presenting: pendingBackup) { parsed in
                Button("Import") {
                    applyImport(parsed)
                }
                Button("Cancel", role: .cancel) { }
            } message: { parsed in
                Text(backupConfirmationMessage(for: parsed))
            }
            .alert(importAlert?.title ?? "", isPresented: $importAlert.isPresent(), presenting: importAlert) { _ in
                Button("OK", role: .cancel) { }
            } message: { alert in
                Text(alert.message)
            }
            .alert("Export Failed", isPresented: $exportError.isPresent(), presenting: exportError) { _ in
                Button("OK", role: .cancel) { }
            } message: { message in
                Text(message)
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

    private var availableTags: [String] {
        let tags = Set(books.flatMap(\.tags).filter { !$0.isEmpty })
        return tags.sorted()
    }

    private var mostRecentlyAdded: [Book] {
        guard let newest = books.map(\.dateAdded).max() else { return [] }
        return books.filter { $0.dateAdded == newest }
    }

    private var filteredBooks: [Book] {
        var result = BookFilter.filter(books, searchText: searchText, visibleStatuses: visibleStatuses, genre: genreFilter)
        if showingRecentlyAdded, let newest = books.map(\.dateAdded).max() {
            result = result.filter { $0.dateAdded == newest }
        }
        return result
    }

    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "Libris-Library-v\(LibraryExporter.schemaVersion)-\(formatter.string(from: Date()))"
    }

    private func backupConfirmationMessage(for parsed: ImportParser.Result) -> String {
        let have = books.count
        let incoming = parsed.fileBookCount
        return "Your library already has \(have) book\(have == 1 ? "" : "s"). This backup contains \(incoming) book\(incoming == 1 ? "" : "s"). Importing adds any books not already in your library and skips duplicates — nothing is deleted or overwritten."
    }

    // MARK: - Mutations

    private func addBook() {
        // Open the editor on a fresh book; it isn't inserted until the user
        // taps Done, so cancelling leaves the library untouched.
        newBook = Book(title: "", author: "")
    }

    /// Moves the book to the Trash, where it can be restored or permanently
    /// removed from the Recently Deleted sheet.
    private func deleteBook(_ book: Book) {
        let title = book.title.whitespaceTrimmed
        let message = title.isEmpty ? "Moved book to the Trash" : "Moved “\(title)” to the Trash"
        book.deletedDate = Date()
        deletionToast = DeletionToast(message: message)
    }

    /// Moves every currently-visible book to the Trash.
    private func deleteAllVisible() {
        let books = filteredBooks
        let now = Date()
        for book in books {
            book.deletedDate = now
        }
        deletionToast = DeletionToast(message: "Moved \(books.count) book\(books.count == 1 ? "" : "s") to the Trash")
    }

    /// A transient post-delete confirmation. The `id` gives `task(id:)` a fresh
    /// value on every delete, so the auto-dismiss timer restarts each time.
    private struct DeletionToast: Identifiable {
        let id = UUID()
        let message: String
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

    /// A backup dropped onto a non-empty library waits for confirmation;
    /// everything else is applied at once.
    private func importBooks(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let parsed = try ImportParser.parse(data, existingBooks: books)
            if parsed.isBackup && !books.isEmpty {
                pendingBackup = parsed
            } else {
                applyImport(parsed)
            }
        } catch let error as ImportParser.ImportError {
            importAlert = .failure(message: error.errorDescription ?? "The file couldn’t be imported.")
        } catch {
            importAlert = .failure(message: error.localizedDescription)
        }
    }

    /// Inserts a parsed file's non-duplicate books and reports the outcome.
    private func applyImport(_ parsed: ImportParser.Result) {
        withAnimation {
            for book in parsed.toAdd {
                modelContext.insert(book)
            }
        }
        importAlert = .summary(added: parsed.toAdd.count, duplicates: parsed.duplicateCount)
    }

    // MARK: - Export

    /// Encodes the library up front so a failure surfaces before the save panel.
    private func prepareExport() {
        do {
            let data = try LibraryExporter.export(books)
            exportDocument = ExportDocument(data: data)
            showingExport = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func handleExport(_ result: Result<URL, Error>) {
        if case .failure(let error) = result {
            if (error as? CocoaError)?.code == .userCancelled { return }
            exportError = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
