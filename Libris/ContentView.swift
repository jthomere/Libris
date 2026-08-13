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

                    Button {
                        prepareExport()
                    } label: {
                        Label("Export Library", systemImage: "square.and.arrow.up.on.square")
                    }
                    .help("Save every book to a file, for backup")
                    .disabled(books.isEmpty)

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
            .fileExporter(
                isPresented: $showingExport,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFilename
            ) { result in
                handleExport(result)
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
            .alert("Import this backup?", isPresented: showingBackupConfirmation, presenting: pendingBackup) { parsed in
                Button("Import") {
                    applyImport(parsed)
                }
                Button("Cancel", role: .cancel) { }
            } message: { parsed in
                Text(backupConfirmationMessage(for: parsed))
            }
            .alert(importAlert?.title ?? "", isPresented: showingImportAlert, presenting: importAlert) { _ in
                Button("OK", role: .cancel) { }
            } message: { alert in
                Text(alert.message)
            }
            .alert("Export Failed", isPresented: showingExportError, presenting: exportError) { _ in
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

    /// Bridges the optional `pendingBackup` to the confirmation's `isPresented`,
    /// discarding the pending books when the confirmation is dismissed.
    private var showingBackupConfirmation: Binding<Bool> {
        Binding(
            get: { pendingBackup != nil },
            set: { if !$0 { pendingBackup = nil } }
        )
    }

    /// Bridges the optional `exportError` to the alert's `isPresented`, clearing
    /// it when the alert is dismissed.
    private var showingExportError: Binding<Bool> {
        Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
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
