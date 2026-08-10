//
//  BookCardView.swift
//  Libris
//
//  A card that displays every field of a book. All fields are directly
//  editable; SwiftData autosaves changes, so edits persist automatically.
//

import SwiftUI

struct BookCardView: View {
    @Bindable var book: Book
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            statusButtons
            ratingRow

            labeledField("Genre") {
                TextField("Genre", text: $book.genre)
                    .textFieldStyle(.roundedBorder)
            }

            labeledField("Description") {
                TextField("Short description", text: $book.bookDescription, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
            }

            labeledField("Note") {
                TextField("A short note", text: $book.note, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
            }

            labeledField("Tags") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Comma-separated, e.g. Staff Pick, Bestseller", text: tagsBinding)
                        .textFieldStyle(.roundedBorder)
                    if !book.tags.isEmpty {
                        tagChips
                    }
                }
            }

            linkField("Goodreads", systemImage: "book.closed", text: $book.goodreadsURL)
            linkField("Amazon", systemImage: "cart", text: $book.amazonURL)
            linkField("Cover image URL", systemImage: "photo", text: $book.coverImageURL)
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    // MARK: - Header (cover + title + author + delete)

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            coverImage

            VStack(alignment: .leading, spacing: 6) {
                TextField("Title", text: $book.title)
                    .font(.title3.weight(.semibold))
                    .textFieldStyle(.plain)
                TextField("Author", text: $book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textFieldStyle(.plain)
            }

            Spacer(minLength: 0)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete this book")
        }
    }

    private var coverImage: some View {
        Group {
            if let url = URLNormalizer.normalized(from: book.coverImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        coverPlaceholder(systemImage: "exclamationmark.triangle")
                    case .empty:
                        ProgressView()
                    @unknown default:
                        coverPlaceholder(systemImage: "book.closed")
                    }
                }
            } else {
                coverPlaceholder(systemImage: "book.closed")
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary, lineWidth: 1))
    }

    private func coverPlaceholder(systemImage: String) -> some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Status buttons

    private var statusButtons: some View {
        HStack(spacing: 8) {
            ForEach(BookStatus.actionable) { status in
                let isActive = book.status == status
                Button {
                    book.toggleStatus(status)
                } label: {
                    Label(status.label, systemImage: status.systemImage)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(isActive ? statusTint(status) : .secondary)
                .background(
                    isActive ? statusTint(status).opacity(0.15) : .clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .help(isActive ? "Tap again to reset to Unsorted" : "Mark as \(status.label)")
            }
        }
    }

    private func statusTint(_ status: BookStatus) -> Color {
        switch status {
        case .toRead:   return .blue
        case .read:     return .green
        case .toRemove: return .red
        case .unsorted: return .secondary
        }
    }

    // MARK: - Rating

    private var ratingRow: some View {
        HStack(spacing: 8) {
            Text("Rating")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            StarRatingView(rating: $book.rating)
            Spacer()
            Text(String(format: "%.1f", book.rating))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tags

    private var tagChips: some View {
        // Simple wrapping row of tag chips.
        FlowLayout(spacing: 6) {
            ForEach(book.tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.tint.opacity(0.15), in: Capsule())
            }
        }
    }

    /// Two-way bridge between the `[String]` tags and a comma-separated field.
    private var tagsBinding: Binding<String> {
        Binding(
            get: { Tags.format(book.tags) },
            set: { book.tags = Tags.parse($0) }
        )
    }

    // MARK: - Reusable field builders

    private func labeledField<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func linkField(_ label: String, systemImage: String, text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
            if let url = URLNormalizer.normalized(from: text.wrappedValue) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                }
                .help("Open \(label)")
            }
        }
    }
}
