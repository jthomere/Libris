//
//  BookCardView.swift
//  Libris
//
//  A read-only card that displays a book's fields.
//

import SwiftUI

struct BookCardView: View {
    let book: Book
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            statusButtons
            ratingRow

            if !book.genre.isEmpty {
                labeledValue("Genre", book.genre)
            }
            if !book.bookDescription.isEmpty {
                labeledValue("Description", book.bookDescription)
            }
            if !book.note.isEmpty {
                labeledValue("Note", book.note)
            }
            if !book.tags.isEmpty {
                labeled("Tags") { tagChips }
            }
            if !linkItems.isEmpty {
                linksRow
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    // MARK: - Header (cover + title + author + edit/delete)

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            coverImage

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title.isEmpty ? "Untitled" : book.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(book.title.isEmpty ? .secondary : .primary)
                Text(book.author.isEmpty ? "Unknown author" : book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Edit this book")

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

    // MARK: - Status buttons (the one interactive quick-action)

    private let statusColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    private var statusButtons: some View {
        LazyVGrid(columns: statusColumns, spacing: 8) {
            ForEach(BookStatus.actionable) { status in
                let isActive = book.status == status
                Button {
                    book.toggleStatus(status)
                } label: {
                    Label(status.label, systemImage: status.systemImage)
                        .font(.caption)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(isActive ? status.tint : .secondary)
                .background(
                    isActive ? status.tint.opacity(0.15) : .clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .help(isActive ? "Tap again to reset to Unsorted" : "Mark as \(status.label)")
            }
        }
    }

    // MARK: - Rating (read-only; imported)

    private var ratingRow: some View {
        HStack(spacing: 8) {
            Text("Rating")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            StarRatingView(rating: .constant(book.rating), isEditable: false)
            Spacer()
            Text(String(format: "%.1f", book.rating))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tags

    private var tagChips: some View {
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

    // MARK: - Links (read-only)

    private var linkItems: [LinkItem] {
        var items: [LinkItem] = []
        if let url = URLNormalizer.normalized(from: book.goodreadsURL) {
            items.append(LinkItem(label: "Goodreads", systemImage: "book.closed", url: url))
        }
        if let url = URLNormalizer.normalized(from: book.amazonURL) {
            items.append(LinkItem(label: "Amazon", systemImage: "cart", url: url))
        }
        if let url = URLNormalizer.normalized(from: book.coverImageURL) {
            items.append(LinkItem(label: "Cover image", systemImage: "photo", url: url))
        }
        return items
    }

    private var linksRow: some View {
        FlowLayout(spacing: 8) {
            ForEach(linkItems) { item in
                Link(destination: item.url) {
                    Label(item.label, systemImage: item.systemImage)
                        .font(.caption)
                }
                .help("Open \(item.label)")
            }
        }
    }

    private struct LinkItem: Identifiable {
        let label: String
        let systemImage: String
        let url: URL
        var id: String { label }
    }

    // MARK: - Reusable display builders

    private func labeledValue(_ label: String, _ value: String) -> some View {
        labeled(label) {
            Text(value)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func labeled<Content: View>(
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
}
