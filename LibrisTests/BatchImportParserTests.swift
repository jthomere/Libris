//
//  BatchImportParserTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct BatchImportParserTests {

    @Test func parsesAllFieldsOfASingleLine() {
        let result = BatchImportParser.parse(
            "Dune | Frank Herbert | Science Fiction | 5 | Staff Pick; Bestseller",
            existingBooks: []
        )
        #expect(result.duplicateCount == 0)
        #expect(result.toAdd.count == 1)

        let book = result.toAdd[0]
        #expect(book.title == "Dune")
        #expect(book.author == "Frank Herbert")
        #expect(book.genre == "Science Fiction")
        #expect(book.rating == 5)
        #expect(book.tags == ["Staff Pick", "Bestseller"])
    }

    @Test func titleOnlyLineIsEnough() {
        let result = BatchImportParser.parse("Educated", existingBooks: [])
        #expect(result.toAdd.count == 1)
        #expect(result.toAdd[0].title == "Educated")
        #expect(result.toAdd[0].author == "")
    }

    @Test func blankAndWhitespaceLinesAreSkipped() {
        let result = BatchImportParser.parse("\n  \nDune\n\n", existingBooks: [])
        #expect(result.toAdd.map(\.title) == ["Dune"])
    }

    @Test func lineWithNoTitleIsSkipped() {
        let result = BatchImportParser.parse(" | Frank Herbert | Science Fiction", existingBooks: [])
        #expect(result.toAdd.isEmpty)
    }

    @Test func ratingIsClampedToZeroThroughFive() {
        let result = BatchImportParser.parse(
            "High | | | 9\nLow | | | -3",
            existingBooks: []
        )
        #expect(result.toAdd.map(\.rating) == [5, 0])
    }

    @Test func invalidRatingDefaultsToZero() {
        let result = BatchImportParser.parse("Dune | Frank Herbert | | abc", existingBooks: [])
        #expect(result.toAdd[0].rating == 0)
    }

    @Test func duplicateOfExistingBookIsSkippedCaseInsensitively() {
        let existing = [Book(title: "Dune", author: "Frank Herbert")]
        let result = BatchImportParser.parse("dune | frank herbert", existingBooks: existing)
        #expect(result.toAdd.isEmpty)
        #expect(result.duplicateCount == 1)
    }

    @Test func duplicateWithinPasteIsSkipped() {
        let result = BatchImportParser.parse(
            "Dune | Frank Herbert\nDune | Frank Herbert",
            existingBooks: []
        )
        #expect(result.toAdd.count == 1)
        #expect(result.duplicateCount == 1)
    }

    @Test func sameTitleDifferentAuthorIsNotADuplicate() {
        let result = BatchImportParser.parse(
            "Selected Poems | Auden\nSelected Poems | Yeats",
            existingBooks: []
        )
        #expect(result.toAdd.count == 2)
        #expect(result.duplicateCount == 0)
    }

    @Test func emptyTagFieldYieldsNoTags() {
        let result = BatchImportParser.parse("Dune | Frank Herbert | | | ", existingBooks: [])
        #expect(result.toAdd[0].tags.isEmpty)
    }
}
