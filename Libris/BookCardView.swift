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
            if let url = URL(string: book.coverImageURL), !book.coverImageURL.isEmpty {
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
            get: { book.tags.joined(separator: ", ") },
            set: { newValue in
                book.tags = newValue
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
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
            if let url = URL(string: text.wrappedValue), !text.wrappedValue.isEmpty {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                }
                .help("Open \(label)")
            }
        }
    }
}

/// A clickable 0–5 star rating control. Clicking a star sets that rating;
/// clicking the leftmost star when the rating is already 1 clears it to 0.
struct StarRatingView: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: Double(index) <= rating.rounded() ? "star.fill" : "star")
                    .foregroundStyle(.yellow)
                    .onTapGesture {
                        let value = Double(index)
                        rating = (rating == value) ? value - 1 : value
                    }
            }
            if rating > 0 {
                Button {
                    rating = 0
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear rating")
            }
        }
    }
}

/// A minimal flow layout that wraps its children onto multiple lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
