//
//  BookFilterTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct BookFilterTests {

    private func makeLibrary() -> [Book] {
        [
            Book(title: "Dune", author: "Frank Herbert", genre: "Science Fiction", status: .toRead),
            Book(title: "Educated", author: "Tara Westover", genre: "Memoir", status: .read),
            Book(title: "Project Hail Mary", author: "Andy Weir", genre: "Science Fiction", status: .toRead)
        ]
    }

    @Test func emptySearchAndNoFiltersReturnsAll() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", status: nil, genre: nil)
        #expect(result.count == 3)
    }

    @Test func searchMatchesTitleCaseInsensitively() {
        let result = BookFilter.filter(makeLibrary(), searchText: "dUnE", status: nil, genre: nil)
        #expect(result.map(\.title) == ["Dune"])
    }

    @Test func searchMatchesAuthor() {
        let result = BookFilter.filter(makeLibrary(), searchText: "WEIR", status: nil, genre: nil)
        #expect(result.map(\.title) == ["Project Hail Mary"])
    }

    @Test func searchWithNoMatchReturnsEmpty() {
        let result = BookFilter.filter(makeLibrary(), searchText: "nonexistent", status: nil, genre: nil)
        #expect(result.isEmpty)
    }

    @Test func statusFilterNarrowsToMatchingStatus() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", status: .read, genre: nil)
        #expect(result.map(\.title) == ["Educated"])
    }

    @Test func genreFilterNarrowsToMatchingGenre() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", status: nil, genre: "Science Fiction")
        #expect(result.map(\.title) == ["Dune", "Project Hail Mary"])
    }

    @Test func filtersAndSearchCombine() {
        let result = BookFilter.filter(makeLibrary(), searchText: "hail", status: nil, genre: "Science Fiction")
        #expect(result.map(\.title) == ["Project Hail Mary"])
    }

    @Test func whitespaceOnlySearchIsTreatedAsEmpty() {
        let result = BookFilter.filter(makeLibrary(), searchText: "   ", status: nil, genre: nil)
        #expect(result.count == 3)
    }
}
