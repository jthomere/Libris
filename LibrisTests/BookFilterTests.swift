//
//  BookFilterTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct BookFilterTests {

    private let allStatuses = Set(BookStatus.allCases)
    private let defaultVisible = Set(BookStatus.allCases).subtracting([.toRemove])

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

    @Test func emptySearchAndAllStatusesReturnsAll() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", visibleStatuses: allStatuses, genre: nil)
        #expect(result.count == 3)
    }

    @Test func searchMatchesTitleCaseInsensitively() {
        let result = BookFilter.filter(makeLibrary(), searchText: "dUnE", visibleStatuses: allStatuses, genre: nil)
        #expect(result.map(\.title) == ["Dune"])
    }

    @Test func searchMatchesAuthor() {
        let result = BookFilter.filter(makeLibrary(), searchText: "WEIR", visibleStatuses: allStatuses, genre: nil)
        #expect(result.map(\.title) == ["Project Hail Mary"])
    }

    @Test func searchWithNoMatchReturnsEmpty() {
        let result = BookFilter.filter(makeLibrary(), searchText: "nonexistent", visibleStatuses: allStatuses, genre: nil)
        #expect(result.isEmpty)
    }

    @Test func visibleStatusesNarrowToSelected() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", visibleStatuses: [.read], genre: nil)
        #expect(result.map(\.title) == ["Educated"])
    }

    @Test func multipleVisibleStatusesShowAllOfThem() {
        let result = BookFilter.filter(makeLibraryWithToRemove(), searchText: "", visibleStatuses: [.read, .toRemove], genre: nil)
        #expect(Set(result.map(\.title)) == ["Educated", "Old Manual"])
    }

    @Test func emptyVisibleStatusesShowsNothing() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", visibleStatuses: [], genre: nil)
        #expect(result.isEmpty)
    }

    @Test func genreFilterNarrowsToMatchingGenre() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", visibleStatuses: allStatuses, genre: "Science Fiction")
        #expect(result.map(\.title) == ["Dune", "Project Hail Mary"])
    }

    @Test func filtersAndSearchCombine() {
        let result = BookFilter.filter(makeLibrary(), searchText: "hail", visibleStatuses: allStatuses, genre: "Science Fiction")
        #expect(result.map(\.title) == ["Project Hail Mary"])
    }

    @Test func whitespaceOnlySearchIsTreatedAsEmpty() {
        let result = BookFilter.filter(makeLibrary(), searchText: "   ", visibleStatuses: allStatuses, genre: nil)
        #expect(result.count == 3)
    }

    @Test func toRemoveHiddenByDefault() {
        let result = BookFilter.filter(makeLibraryWithToRemove(), searchText: "", visibleStatuses: defaultVisible, genre: nil)
        #expect(!result.map(\.title).contains("Old Manual"))
        #expect(result.count == 3)
    }

    @Test func includingToRemoveShowsThoseBooks() {
        let result = BookFilter.filter(makeLibraryWithToRemove(), searchText: "", visibleStatuses: allStatuses, genre: nil)
        #expect(result.map(\.title).contains("Old Manual"))
        #expect(result.count == 4)
    }

    @Test func onlyToRemoveShowsOnlyThoseBooks() {
        let result = BookFilter.filter(makeLibraryWithToRemove(), searchText: "", visibleStatuses: [.toRemove], genre: nil)
        #expect(result.map(\.title) == ["Old Manual"])
    }
}
