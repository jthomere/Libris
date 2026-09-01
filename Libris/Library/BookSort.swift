//
//  BookSort.swift
//  Libris
//

import Foundation

/// How the library grid is ordered: a key plus a direction. Each key knows the
/// direction it starts in when first chosen, and how to bucket books into the
/// grid's sections.
struct BookSort: Equatable {
    enum Key: String, CaseIterable, Identifiable {
        case dateAdded
        case title
        case author
        case rating

        var id: String { rawValue }

        var label: String {
            switch self {
            case .dateAdded: return "Date Added"
            case .title:     return "Title"
            case .author:    return "Author"
            case .rating:    return "Rating"
            }
        }

        /// The direction applied when the user first selects this key.
        var startsAscending: Bool {
            switch self {
            case .title, .author: return true    // A→Z
            case .dateAdded:      return false    // newest first
            case .rating:         return false    // highest first
            }
        }
    }

    var key: Key
    var ascending: Bool

    static let `default` = BookSort(key: .dateAdded, ascending: false)

    /// Sorts `books`, then groups them into the grid's sections in display
    /// order. Books are ordered first and bucketed while preserving that order,
    /// so both the sections and their contents follow the current direction.
    func sections(from books: [Book]) -> [BookSection] {
        let sorted = books.sorted(by: areInOrder)
        var sections: [BookSection] = []
        for book in sorted {
            let bucket = sectionBucket(for: book)
            if var last = sections.last, last.id == bucket.id {
                last.books.append(book)
                sections[sections.count - 1] = last
            } else {
                sections.append(BookSection(id: bucket.id, title: bucket.title, books: [book]))
            }
        }
        return sections
    }

    // MARK: - Ordering

    private func areInOrder(_ a: Book, _ b: Book) -> Bool {
        let primary = compare(a, b)
        if primary != .orderedSame {
            return ascending ? primary == .orderedAscending : primary == .orderedDescending
        }
        // Ties always fall back to Title A→Z, whichever way the primary sorts.
        return a.title.localizedStandardCompare(b.title) == .orderedAscending
    }

    private func compare(_ a: Book, _ b: Book) -> ComparisonResult {
        switch key {
        case .title:     return a.title.localizedStandardCompare(b.title)
        case .author:    return authorKey(a.author).localizedStandardCompare(authorKey(b.author))
        case .dateAdded: return compareValues(a.dateAdded, b.dateAdded)
        case .rating:    return compareValues(a.rating, b.rating)
        }
    }

    private func compareValues<T: Comparable>(_ a: T, _ b: T) -> ComparisonResult {
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }

    // MARK: - Section buckets

    private func sectionBucket(for book: Book) -> (id: String, title: String) {
        switch key {
        case .dateAdded:
            // One section per import: every book in a batch shares an instant.
            let date = book.dateAdded
            return (String(date.timeIntervalSinceReferenceDate),
                    date.formatted(date: .long, time: .shortened))
        case .rating:
            if book.rating <= 0 { return ("unrated", "Unrated") }
            let stars = min(max(Int(book.rating.rounded()), 1), 5)
            return ("rating-\(stars)", "\(stars) \(stars == 1 ? "Star" : "Stars")")
        case .title:
            let bucket = alphaBucket(book.title)
            return (bucket, bucket)
        case .author:
            let bucket = alphaBucket(authorLastName(book.author))
            return (bucket, bucket)
        }
    }

    /// A sort key that orders authors by last name, then by the full name so
    /// authors who share a surname stay in a stable first-name order.
    private func authorKey(_ author: String) -> String {
        "\(authorLastName(author))\u{0}\(author)"
    }

    /// The last whitespace-separated word of an author's name, used as the
    /// surname for sorting and section grouping ("" for an empty name).
    private func authorLastName(_ author: String) -> String {
        let trimmed = author.whitespaceTrimmed
        guard let last = trimmed.split(whereSeparator: \.isWhitespace).last else { return trimmed }
        return String(last)
    }

    /// The first-letter bucket for a title or author, or "#" for anything that
    /// doesn't start with a letter (numbers, symbols, or an empty string).
    private func alphaBucket(_ string: String) -> String {
        guard let first = string.whitespaceTrimmed.first else { return "#" }
        let upper = String(first).uppercased()
        return upper.first?.isLetter == true ? upper : "#"
    }
}
