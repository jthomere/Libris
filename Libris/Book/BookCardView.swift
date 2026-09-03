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
        VStack(alignment: .leading, spacing: 10) {
            header

            if !book.bookDescription.isEmpty {
                Text(book.bookDescription)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !book.note.isEmpty {
                Text(book.note)
                    .font(.body.italic())
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !book.tags.isEmpty {
                tagChips
            }
            bottomBar
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    // MARK: - Header (cover + rating | genre + title + author | status | actions)

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            coverImage

            VStack(alignment: .leading, spacing: 4) {
                if !book.genre.isEmpty {
                    Text(book.genre.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(book.title.isEmpty ? "Untitled" : book.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(book.title.isEmpty ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(book.author.isEmpty ? "Unknown author" : book.author)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if book.rating > 0 {
                    StarRatingView(rating: .constant(book.rating), isEditable: false)
                        .font(.caption)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            statusPile
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let url = URLNormalizer.normalized(from: book.coverImageURL) {
            CachedCoverImage(url: url, width: 100, height: 150)
        }
    }

    // MARK: - Status (a vertical pile of named quick-action toggles)

    private var statusPile: some View {
        VStack(alignment: .center, spacing: 4) {
            ForEach(BookStatus.actionable) { status in
                let isActive = book.status == status
                Button {
                    book.toggleStatus(status)
                } label: {
                    Text(status.label)
                        .font(isActive ? .subheadline.weight(.semibold) : .caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.vertical, isActive ? 6 : 4)
                        .frame(width: isActive ? 108 : 96)
                        .foregroundStyle(isActive ? AnyShapeStyle(status.onTint) : AnyShapeStyle(.secondary))
                        .background(
                            isActive ? AnyShapeStyle(status.tint) : AnyShapeStyle(.quaternary),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .help(isActive ? "Tap again to clear the status" : "Mark as \(status.label)")
            }
        }
        .frame(width: 116, alignment: .center)
    }

    // MARK: - Tags

    private var tagChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(book.tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.tint.opacity(0.15), in: Capsule())
            }
        }
    }

    // MARK: - Bottom bar (links on the left, edit/delete in the lower-right corner)

    private var bottomBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !linkItems.isEmpty {
                linksRow
            }
            Spacer(minLength: 8)
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
                        .font(.footnote)
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
}

#Preview {
    let sample = Book(
        title: "I Heard There Was a Secret Chord: Music as Medicine and the Emerging Science of Sound, Rhythm, and the Human Brain",
        author: "Daniel J. Levitin, with a foreword by Oliver Sacks",
        isbn: "978-0-593-65600-0",
        bookDescription: "A neuroscientist and musician explores music's long history as medicine across cultures and centuries, drawing on the emerging science of how rhythm, melody, and sound can ease chronic pain, slow the progression of Parkinson's disease, sharpen memory in aging brains, and lift the fog of depression and anxiety.",
        genre: "Popular Science / Neuroscience & Music Therapy",
        rating: 4.5,
        goodreadsURL: "https://www.goodreads.com/book/show/195790834",
        amazonURL: "https://www.amazon.com/dp/0593656008",
        note: "Recommended by the reading group; start with the chapter on memory, then loop back to the sections on rhythm and movement disorders before the final discussion.",
        tags: ["Bestseller", "Science", "Music", "Health", "Neuroscience", "Nonfiction", "Reading Group Pick"],
        status: .toRead
    )
    return BookCardView(book: sample, onEdit: {}, onDelete: {})
        .frame(width: 360)
        .padding()
}
