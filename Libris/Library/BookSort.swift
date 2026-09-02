//
//  BookSort.swift
//  Libris
//

import Foundation

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

    // Sorts first, then buckets in that order, so both the sections and their
    // contents follow the current direction.
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
            // Bucket by the displayed minute so a section's id is its header —
            // no two sections can then show the same title.
            let title = book.dateAdded.formatted(date: .long, time: .shortened)
            return (title, title)
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

    // Surname, then full name (via a NUL separator) so shared surnames keep a
    // stable first-name order.
    private func authorKey(_ author: String) -> String {
        "\(authorLastName(author))\u{0}\(author)"
    }

    private func authorLastName(_ author: String) -> String {
        let trimmed = author.whitespaceTrimmed
        guard let last = trimmed.split(whereSeparator: \.isWhitespace).last else { return trimmed }
        return String(last)
    }

    // First letter of the uppercased result only — some letters expand when
    // uppercased ("ß" → "SS") — or "#" when it isn't a letter.
    private func alphaBucket(_ string: String) -> String {
        guard let first = string.whitespaceTrimmed.first,
              let letter = String(first).uppercased().first,
              letter.isLetter else { return "#" }
        return String(letter)
    }
}
