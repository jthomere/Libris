//
//  BookMiniCardView.swift
//  Libris
//
//  A compact, cover-forward tile used in the library's Mini view mode.
//

import SwiftUI
import AppKit

struct BookMiniCardView: View {
    let book: Book
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CoverTile(book: book)
            HStack(alignment: .top, spacing: 6) {
                caption
                statusBadge
            }
            if book.rating > 0 {
                StarRatingView(rating: .constant(book.rating), isEditable: false)
                    .font(.caption2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onEdit() }
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
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
        @State private var image: NSImage?

        var body: some View {
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
                .task(id: book.coverImageURL) {
                image = nil
                guard let url = URLNormalizer.normalized(from: book.coverImageURL) else { return }
                if let loaded = await CoverImageCache.shared.image(for: url) {
                    image = loaded
                }
            }
        }

    }

    /// A generated "cover" for books without a cover image: title and author
    /// set typographically over a vibrant, per-book gradient.
    private struct PlaceholderCover: View {
        let book: Book

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("Futura-CondensedExtraBold", size: 34))
                    .lineLimit(6)
                    .minimumScaleFactor(0.45)
                Spacer(minLength: 8)
                Text(author)
                    .font(.custom("Futura-Medium", size: 15))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(gradient)
        }

        private var title: String { book.title.isEmpty ? "Untitled" : book.title }
        private var author: String { book.author.isEmpty ? "Unknown author" : book.author }

        /// A diagonal gradient with a random-looking (but stable) per-book hue and
        /// a saturation keyed to status: engaged statuses are vivid, dismissed
        /// ones drab.
        private var gradient: LinearGradient {
            let h = hue
            let s = saturation
            return LinearGradient(
                colors: [
                    Color(hue: h, saturation: s, brightness: 0.85),
                    Color(hue: (h + 0.08).truncatingRemainder(dividingBy: 1), saturation: min(s + 0.12, 1), brightness: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// A stable 0–1 hue from title + author (djb2), so each book gets its own
        /// color that survives relaunches and doesn't flicker while scrolling.
        private var hue: Double {
            var hash: UInt64 = 5381
            for byte in "\(title)|\(author)".utf8 { hash = (hash &* 33) ^ UInt64(byte) }
            return Double(hash % 360) / 360.0
        }

        /// How vivid the cover is, from anticipation (To Read) down to dismissal
        /// (Not Interested).
        private var saturation: Double {
            switch book.status {
            case .toRead:        return 0.85
            case .read:          return 0.70
            case .notSure:       return 0.55
            case .didNotFinish:  return 0.42
            case .gaveUp:        return 0.32
            case .notInterested: return 0.15
            case nil:            return 0.55
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
