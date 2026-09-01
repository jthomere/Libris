//
//  BookFilterTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct BookFilterTests {

    private let allStatuses = StatusPreset.all.statuses
    private let defaultVisible = StatusPreset.default.statuses

    private func makeLibrary() -> [Book] {
        [
            Book(title: "Dune", author: "Frank Herbert", genre: "Science Fiction", status: .toRead),
            Book(title: "Educated", author: "Tara Westover", genre: "Memoir", status: .read),
            Book(title: "Project Hail Mary", author: "Andy Weir", genre: "Science Fiction", status: .toRead)
        ]
    }

    private func makeLibraryWithNotInterested() -> [Book] {
        makeLibrary() + [
            Book(title: "Old Manual", author: "Anon", genre: "Reference", status: .notInterested)
        ]
    }

    @Test func emptySearchAndAllStatusesReturnsAll() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", visibleStatuses: allStatuses, genres: [])
        #expect(result.count == 3)
    }

    @Test func searchMatchesTitleCaseInsensitively() {
        let result = BookFilter.filter(makeLibrary(), searchText: "dUnE", visibleStatuses: allStatuses, genres: [])
        #expect(result.map(\.title) == ["Dune"])
    }

    @Test func searchMatchesAuthor() {
        let result = BookFilter.filter(makeLibrary(), searchText: "WEIR", visibleStatuses: allStatuses, genres: [])
        #expect(result.map(\.title) == ["Project Hail Mary"])
    }

    @Test func searchWithNoMatchReturnsEmpty() {
        let result = BookFilter.filter(makeLibrary(), searchText: "nonexistent", visibleStatuses: allStatuses, genres: [])
        #expect(result.isEmpty)
    }

    @Test func visibleStatusesNarrowToSelected() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", visibleStatuses: [.read], genres: [])
        #expect(result.map(\.title) == ["Educated"])
    }

    @Test func multipleVisibleStatusesShowAllOfThem() {
        let result = BookFilter.filter(makeLibraryWithNotInterested(), searchText: "", visibleStatuses: [.read, .notInterested], genres: [])
        #expect(Set(result.map(\.title)) == ["Educated", "Old Manual"])
    }

    @Test func emptyVisibleStatusesShowsNothing() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", visibleStatuses: [], genres: [])
        #expect(result.isEmpty)
    }

    @Test func genreFilterNarrowsToMatchingGenre() {
        let result = BookFilter.filter(makeLibrary(), searchText: "", visibleStatuses: allStatuses, genres: ["Science Fiction"])
        #expect(result.map(\.title) == ["Dune", "Project Hail Mary"])
    }

    @Test func filtersAndSearchCombine() {
        let result = BookFilter.filter(makeLibrary(), searchText: "hail", visibleStatuses: allStatuses, genres: ["Science Fiction"])
        #expect(result.map(\.title) == ["Project Hail Mary"])
    }

    @Test func whitespaceOnlySearchIsTreatedAsEmpty() {
        let result = BookFilter.filter(makeLibrary(), searchText: "   ", visibleStatuses: allStatuses, genres: [])
        #expect(result.count == 3)
    }

    @Test func notInterestedHiddenByDefault() {
        let result = BookFilter.filter(makeLibraryWithNotInterested(), searchText: "", visibleStatuses: defaultVisible, genres: [])
        #expect(!result.map(\.title).contains("Old Manual"))
        #expect(result.count == 3)
    }

    @Test func includingNotInterestedShowsThoseBooks() {
        let result = BookFilter.filter(makeLibraryWithNotInterested(), searchText: "", visibleStatuses: allStatuses, genres: [])
        #expect(result.map(\.title).contains("Old Manual"))
        #expect(result.count == 4)
    }

    @Test func onlyNotInterestedShowsOnlyThoseBooks() {
        let result = BookFilter.filter(makeLibraryWithNotInterested(), searchText: "", visibleStatuses: [.notInterested], genres: [])
        #expect(result.map(\.title) == ["Old Manual"])
    }

    @Test func noneFacetHidesAndShowsStatuslessBooks() {
        let library = makeLibrary() + [Book(title: "Undecided", author: "Anon")]

        let withoutNone = BookFilter.filter(library, searchText: "", visibleStatuses: [.toRead, .read], genres: [])
        #expect(!withoutNone.map(\.title).contains("Undecided"))

        let withNone = BookFilter.filter(library, searchText: "", visibleStatuses: [.toRead, .read, nil], genres: [])
        #expect(withNone.map(\.title).contains("Undecided"))
    }
}
