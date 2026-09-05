//
//  BookSortTests.swift
//  LibrisTests
//

import Testing
import Foundation
@testable import Libris

struct BookSortTests {

    private func book(_ title: String, author: String = "", rating: Double = 0, status: BookStatus? = nil, dateAdded: Date = Date()) -> Book {
        Book(title: title, author: author, rating: rating, status: status, dateAdded: dateAdded)
    }

    private func titles(_ sections: [BookSection]) -> [String] {
        sections.flatMap { $0.books.map(\.title) }
    }

    // MARK: - Title

    @Test func titleAscendingOrdersAToZ() {
        let books = [book("Charlie"), book("alpha"), book("Bravo")]
        let sorted = BookSort(key: .title, ascending: true).sections(from: books)
        #expect(titles(sorted) == ["alpha", "Bravo", "Charlie"])
    }

    @Test func titleDescendingReversesOrder() {
        let books = [book("alpha"), book("Bravo"), book("Charlie")]
        let sorted = BookSort(key: .title, ascending: false).sections(from: books)
        #expect(titles(sorted) == ["Charlie", "Bravo", "alpha"])
    }

    @Test func titleSectionsBucketByFirstLetterWithSymbolFallback() {
        let books = [book("Apple"), book("Avocado"), book("42"), book("Banana")]
        let sections = BookSort(key: .title, ascending: true).sections(from: books)
        let byBucket = Dictionary(uniqueKeysWithValues: sections.map { ($0.title, $0.books.map(\.title)) })
        #expect(byBucket["#"] == ["42"])
        #expect(byBucket["A"] == ["Apple", "Avocado"])
        #expect(byBucket["B"] == ["Banana"])
    }

    @Test func titleBucketStaysSingleCharacterWhenUppercaseExpands() {
        // "ß".uppercased() is "SS"; the bucket must still be a single letter.
        let sections = BookSort(key: .title, ascending: true).sections(from: [book("ßfoo")])
        #expect(sections.map(\.title) == ["S"])
    }

    // MARK: - Rating

    @Test func ratingDescendingHighestFirstThenUnrated() {
        let books = [book("a", rating: 0), book("b", rating: 5), book("c", rating: 3)]
        let sections = BookSort(key: .rating, ascending: false).sections(from: books)
        #expect(sections.map(\.title) == ["5 Stars", "3 Stars", "Unrated"])
    }

    @Test func ratingAscendingSurfacesUnratedFirst() {
        let books = [book("a", rating: 4), book("b", rating: 0), book("c", rating: 1)]
        let sections = BookSort(key: .rating, ascending: true).sections(from: books)
        #expect(sections.map(\.title) == ["Unrated", "1 Star", "4 Stars"])
    }

    @Test func ratingRoundsToNearestStar() {
        let books = [book("a", rating: 4.5), book("b", rating: 2.4)]
        let sections = BookSort(key: .rating, ascending: false).sections(from: books)
        let byBucket = Dictionary(uniqueKeysWithValues: sections.map { ($0.title, $0.books.map(\.title)) })
        #expect(byBucket["5 Stars"] == ["a"])   // 4.5 rounds up
        #expect(byBucket["2 Stars"] == ["b"])   // 2.4 rounds down
    }

    @Test func withinRatingBreaksTiesByTitle() {
        let books = [book("Zebra", rating: 3), book("Apple", rating: 3)]
        let section = BookSort(key: .rating, ascending: false).sections(from: books).first
        #expect(section?.title == "3 Stars")
        #expect(section?.books.map(\.title) == ["Apple", "Zebra"])
    }

    // MARK: - Date Added

    @Test func dateAddedGroupsPerImportNewestFirst() {
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        let books = [
            book("A", dateAdded: older),
            book("B", dateAdded: newer),
            book("C", dateAdded: older)
        ]
        let sections = BookSort(key: .dateAdded, ascending: false).sections(from: books)
        #expect(sections.count == 2)
        #expect(sections[0].books.map(\.title) == ["B"])         // newest import first
        #expect(sections[1].books.map(\.title) == ["A", "C"])    // same import, tie by title
    }

    @Test func dateAddedAscendingOldestFirst() {
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        let books = [book("B", dateAdded: newer), book("A", dateAdded: older)]
        let sections = BookSort(key: .dateAdded, ascending: true).sections(from: books)
        #expect(sections.map { $0.books.map(\.title) } == [["A"], ["B"]])
    }

    // MARK: - Author

    @Test func authorSortsAndGroupsBySurname() {
        let books = [
            book("t1", author: "Frank Herbert"),
            book("t2", author: "Andy Weir"),
            book("t3", author: "Ursula Le Guin")   // surname taken as "Guin" — see #42
        ]
        let sections = BookSort(key: .author, ascending: true).sections(from: books)
        #expect(sections.map(\.title) == ["G", "H", "W"])
    }

    @Test func authorTiesBySurnameThenFullName() {
        let books = [
            book("t1", author: "Frank Herbert"),
            book("t2", author: "Brian Herbert")
        ]
        let section = BookSort(key: .author, ascending: true).sections(from: books).first
        #expect(section?.title == "H")
        #expect(section?.books.map(\.author) == ["Brian Herbert", "Frank Herbert"])
    }

    // MARK: - Status

    @Test func statusAscendingOrdersByWorkflowWithNoStatusFirst() {
        let books = [
            book("a", status: .notInterested),
            book("b", status: .toRead),
            book("c", status: nil),
            book("d", status: .didNotFinish),
            book("e", status: .read)
        ]
        let sections = BookSort(key: .status, ascending: true).sections(from: books)
        #expect(sections.map(\.title) == ["No Status", "To Read", "Read", "Did Not Finish", "Not Interested"])
    }

    @Test func statusDescendingReversesOrderWithNoStatusLast() {
        let books = [
            book("a", status: .toRead),
            book("b", status: nil),
            book("c", status: .notInterested)
        ]
        let sections = BookSort(key: .status, ascending: false).sections(from: books)
        #expect(sections.map(\.title) == ["Not Interested", "To Read", "No Status"])
    }

    @Test func statusBucketsNilAsNoStatus() {
        let sections = BookSort(key: .status, ascending: true).sections(from: [book("a", status: nil)])
        #expect(sections.map(\.title) == ["No Status"])
    }

    @Test func withinStatusBreaksTiesByTitle() {
        let books = [book("Zebra", status: .read), book("Apple", status: .read)]
        let section = BookSort(key: .status, ascending: true).sections(from: books).first
        #expect(section?.title == "Read")
        #expect(section?.books.map(\.title) == ["Apple", "Zebra"])
    }
}
