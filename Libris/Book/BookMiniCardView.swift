//
//  BookMiniCardView.swift
//  Libris
//
//  A compact, cover-forward tile used in the library's Mini view mode.
//

import SwiftUI

struct BookMiniCardView: View {
    let book: Book
    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var showingPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CoverTile(book: book)
            HStack(alignment: .top, spacing: 6) {
                caption
                statusBadge
            }
            bottomBar
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { showingPreview = true }
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
        .popover(isPresented: $showingPreview, arrowEdge: .trailing) {
            BookCardView(
                book: book,
                onEdit: {
                    showingPreview = false
                    onEdit()
                },
                onDelete: {
                    showingPreview = false
                    onDelete()
                }
            )
            .frame(width: 360)
            .padding(12)
        }
    }

    // MARK: - Caption

    private var caption: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(book.title.isEmpty ? "Untitled" : book.title)
                .font(.callout.weight(.medium))
                .foregroundStyle(book.title.isEmpty ? .secondary : .primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            Text(book.author.isEmpty ? "Unknown author" : book.author)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom bar (rating on the left, edit/delete in the lower-right corner)

    private var bottomBar: some View {
        HStack(spacing: 8) {
            if book.rating > 0 {
                StarRatingView(rating: .constant(book.rating), isEditable: false)
                    .font(.caption2)
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

    // MARK: - Status badge (click to change)

    private var statusBadge: some View {
        Menu {
            ForEach(BookStatus.actionable) { status in
                Button {
                    book.toggleStatus(status)
                } label: {
                    if book.status == status {
                        Label(status.label, systemImage: "checkmark")
                    } else {
                        Text(status.label)
                    }
                }
            }
        } label: {
            Text(book.status?.label ?? "No status")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(badgeFill, in: Capsule())
                .foregroundStyle(badgeText)
                .overlay(Capsule().stroke(.white.opacity(0.4), lineWidth: 0.5))
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .fixedSize()
        .help("Set reading status")
    }

    private var badgeFill: AnyShapeStyle {
        if let status = book.status { return AnyShapeStyle(status.tint) }
        return AnyShapeStyle(.thinMaterial)
    }

    private var badgeText: AnyShapeStyle {
        if let status = book.status { return AnyShapeStyle(status.onTint) }
        return AnyShapeStyle(.secondary)
    }

    // MARK: - Cover tile (image, or a status-tinted placeholder)

    private struct CoverTile: View {
        let book: Book

        var body: some View {
            CoverImageLoader(url: URLNormalizer.normalized(from: book.coverImageURL)) { image in
                Color.clear
                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        if let image {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            PlaceholderCover(book: book)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 1))
            }
        }
    }
}

#Preview {
    let sample = Book(
        title: "The Left Hand of Darkness",
        author: "Ursula K. Le Guin",
        genre: "Science Fiction",
        rating: 4.5,
        status: .read
    )
    return BookMiniCardView(book: sample, onEdit: {}, onDelete: {})
        .frame(width: 170)
        .padding()
}
