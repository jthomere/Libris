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

    private func makeLibraryWithToRemove() -> [Book] {
        makeLibrary() + [
            Book(title: "Old Manual", author: "Anon", genre: "Reference", status: .toRemove)
        ]
    }

    @Test func emptySearchAndNoFiltersReturnsAll() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", status: nil, genre: nil, hideToRemove: true)
        #expect(result.count == 3)
    }

    @Test func searchMatchesTitleCaseInsensitively() {
        let result = BookFilter.filter(makeLibrary(), searchText: "dUnE", status: nil, genre: nil, hideToRemove: true)
        #expect(result.map(\.title) == ["Dune"])
    }

    @Test func searchMatchesAuthor() {
        let result = BookFilter.filter(makeLibrary(), searchText: "WEIR", status: nil, genre: nil, hideToRemove: true)
        #expect(result.map(\.title) == ["Project Hail Mary"])
    }

    @Test func searchWithNoMatchReturnsEmpty() {
        let result = BookFilter.filter(makeLibrary(), searchText: "nonexistent", status: nil, genre: nil, hideToRemove: true)
        #expect(result.isEmpty)
    }

    @Test func statusFilterNarrowsToMatchingStatus() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", status: .read, genre: nil, hideToRemove: true)
        #expect(result.map(\.title) == ["Educated"])
    }

    @Test func genreFilterNarrowsToMatchingGenre() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", status: nil, genre: "Science Fiction", hideToRemove: true)
        #expect(result.map(\.title) == ["Dune", "Project Hail Mary"])
    }

    @Test func filtersAndSearchCombine() {
        let result = BookFilter.filter(makeLibrary(), searchText: "hail", status: nil, genre: "Science Fiction", hideToRemove: true)
        #expect(result.map(\.title) == ["Project Hail Mary"])
    }

    @Test func whitespaceOnlySearchIsTreatedAsEmpty() {
        let result = BookFilter.filter(makeLibrary(), searchText: "   ", status: nil, genre: nil, hideToRemove: true)
        #expect(result.count == 3)
    }

    @Test func toRemoveHiddenByDefault() {
        let result = BookFilter.filter(makeLibraryWithToRemove(), searchText: "", status: nil, genre: nil, hideToRemove: true)
        #expect(!result.map(\.title).contains("Old Manual"))
        #expect(result.count == 3)
    }

    @Test func notHidingShowsToRemoveBooks() {
        let result = BookFilter.filter(makeLibraryWithToRemove(), searchText: "", status: nil, genre: nil, hideToRemove: false)
        #expect(result.map(\.title).contains("Old Manual"))
        #expect(result.count == 4)
    }

    @Test func explicitToRemoveStatusShowsThemEvenWhenHidden() {
        let result = BookFilter.filter(makeLibraryWithToRemove(), searchText: "", status: .toRemove, genre: nil, hideToRemove: true)
        #expect(result.map(\.title) == ["Old Manual"])
    }
}
