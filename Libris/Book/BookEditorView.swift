//
//  BookEditorView.swift
//  Libris
//
//  A modal sheet for editing a book's fields.
//

import SwiftUI

struct BookEditorView: View {
    let book: Book
    let navigationTitle: String
    var onCancel: () -> Void
    var onSave: () -> Void

    // Draft state, seeded from the book. Nothing here touches `book` until Save.
    @State private var title: String
    @State private var author: String
    @State private var genre: String
    @State private var bookDescription: String
    @State private var note: String
    @State private var tagsText: String
    @State private var rating: Double
    @State private var goodreadsURL: String
    @State private var amazonURL: String
    @State private var coverImageURL: String

    init(
        book: Book,
        navigationTitle: String,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.book = book
        self.navigationTitle = navigationTitle
        self.onCancel = onCancel
        self.onSave = onSave
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _genre = State(initialValue: book.genre)
        _bookDescription = State(initialValue: book.bookDescription)
        _note = State(initialValue: book.note)
        _tagsText = State(initialValue: Tags.format(book.tags))
        _rating = State(initialValue: book.rating)
        _goodreadsURL = State(initialValue: book.goodreadsURL)
        _amazonURL = State(initialValue: book.amazonURL)
        _coverImageURL = State(initialValue: book.coverImageURL)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    labeled("Title") {
                        TextField("Title", text: $title, prompt: Text("Required"))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }

                    labeled("Author") {
                        TextField("Author", text: $author, prompt: Text("Author name"))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }

                    labeled("Genre") {
                        TextField("Genre", text: $genre, prompt: Text("e.g. Memoir"))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }

                    labeled("Rating") {
                        StarRatingView(rating: $rating)
                    }

                    labeled("Description") {
                        TextField("Description", text: $bookDescription,
                                  prompt: Text("A short description of the book"), axis: .vertical)
                            .lineLimit(2...5)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }

                    labeled("Note") {
                        TextField("Note", text: $note,
                                  prompt: Text("A private note — e.g. who recommended it"), axis: .vertical)
                            .lineLimit(1...4)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }

                    labeled("Tags") {
                        TextField("Tags", text: $tagsText,
                                  prompt: Text("Comma-separated, e.g. Staff Pick, Bestseller"))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }

                    labeled("Goodreads") {
                        linkField("Goodreads", systemImage: "book.closed",
                                  prompt: "goodreads.com/book/…", text: $goodreadsURL)
                    }

                    labeled("Amazon") {
                        linkField("Amazon", systemImage: "cart",
                                  prompt: "amazon.com/dp/…", text: $amazonURL)
                    }

                    labeled("Cover image URL") {
                        linkField("Cover image URL", systemImage: "photo",
                                  prompt: "https://…/cover.jpg", text: $coverImageURL)
                    }
                }
                .padding(20)
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        apply()
                        onSave()
                    }
                    .disabled(!hasTitle)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 580)
    }

    private var hasTitle: Bool {
        !title.isBlank
    }

    /// Writes the draft back to the book. Called only on Done.
    private func apply() {
        book.title = title.whitespaceTrimmed
        book.author = author.whitespaceTrimmed
        book.genre = genre.whitespaceTrimmed
        book.bookDescription = bookDescription.whitespaceTrimmed
        book.note = note.whitespaceTrimmed
        book.tags = Tags.parse(tagsText)
        book.rating = rating
        book.goodreadsURL = goodreadsURL.whitespaceTrimmed
        book.amazonURL = amazonURL.whitespaceTrimmed
        book.coverImageURL = coverImageURL.whitespaceTrimmed
    }

    // MARK: - Field builders

    /// A small secondary caption above its editable content.
    private func labeled<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func linkField(_ label: String, systemImage: String, prompt: String, text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            TextField(label, text: text, prompt: Text(prompt))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
        }
    }
}
