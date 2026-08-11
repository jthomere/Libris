//
//  ImportParserTests.swift
//  LibrisTests
//

import Foundation
import Testing
@testable import Libris

struct ImportParserTests {

    private func data(_ json: String) -> Data {
        Data(json.utf8)
    }

    @Test func parsesAllFieldsIntoBook() throws {
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            {
              "title": "Project Hail Mary",
              "author": "Andy Weir",
              "isbn": "9780593135204",
              "genre": "Science Fiction",
              "rating": 4.5,
              "bookDescription": "A lone astronaut wakes with no memory.",
              "note": "Recommended by a friend.",
              "tags": ["Staff Pick", "SF"],
              "goodreadsURL": "https://www.goodreads.com/book/show/54493401",
              "amazonURL": "https://www.amazon.com/dp/0593135202",
              "coverImageURL": "https://covers.openlibrary.org/b/isbn/0593135202-M.jpg"
            }
          ]
        }
        """), existingBooks: [])

        #expect(result.toAdd.count == 1)
        #expect(result.duplicateCount == 0)
        let book = try #require(result.toAdd.first)
        #expect(book.title == "Project Hail Mary")
        #expect(book.author == "Andy Weir")
        #expect(book.isbn == "9780593135204")
        #expect(book.genre == "Science Fiction")
        #expect(book.rating == 4.5)
        #expect(book.bookDescription == "A lone astronaut wakes with no memory.")
        #expect(book.note == "Recommended by a friend.")
        #expect(book.tags == ["Staff Pick", "SF"])
        #expect(book.goodreadsURL == "https://www.goodreads.com/book/show/54493401")
        #expect(book.amazonURL == "https://www.amazon.com/dp/0593135202")
        #expect(book.coverImageURL == "https://covers.openlibrary.org/b/isbn/0593135202-M.jpg")
        #expect(book.status == .unsorted)
    }

    @Test func optionalFieldsDefaultWhenOmitted() throws {
        let result = try ImportParser.parse(data("""
        { "schemaVersion": 1, "books": [ { "title": "Bare" } ] }
        """), existingBooks: [])

        let book = try #require(result.toAdd.first)
        #expect(book.title == "Bare")
        #expect(book.author == "")
        #expect(book.isbn == "")
        #expect(book.genre == "")
        #expect(book.rating == 0)
        #expect(book.bookDescription == "")
        #expect(book.note == "")
        #expect(book.tags == [])
        #expect(book.goodreadsURL == "")
    }

    @Test func ratingIsClampedToZeroThroughFive() throws {
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            { "title": "High", "rating": 9.2 },
            { "title": "Low", "rating": -3 }
          ]
        }
        """), existingBooks: [])

        #expect(result.toAdd[0].rating == 5)
        #expect(result.toAdd[1].rating == 0)
    }

    @Test func tagsAreTrimmedAndEmptiesDropped() throws {
        let result = try ImportParser.parse(data("""
        { "schemaVersion": 1, "books": [ { "title": "T", "tags": [" a ", "", "  ", "b"] } ] }
        """), existingBooks: [])

        #expect(result.toAdd.first?.tags == ["a", "b"])
    }

    @Test func skipsBooksWithBlankTitle() throws {
        let result = try ImportParser.parse(data("""
        { "schemaVersion": 1, "books": [ { "title": "   " }, { "title": "Keep" } ] }
        """), existingBooks: [])

        #expect(result.toAdd.map(\.title) == ["Keep"])
    }

    @Test func skipsDuplicatesOfExistingBooks() throws {
        let existing = [Book(title: "Dune", author: "Frank Herbert")]
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            { "title": "Dune", "author": "Frank Herbert" },
            { "title": "New", "author": "Someone" }
          ]
        }
        """), existingBooks: existing)

        #expect(result.toAdd.map(\.title) == ["New"])
        #expect(result.duplicateCount == 1)
    }

    @Test func deduplicatesWithinTheFileCaseInsensitively() throws {
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            { "title": "Dune", "author": "Frank Herbert" },
            { "title": "dune", "author": "frank herbert" }
          ]
        }
        """), existingBooks: [])

        #expect(result.toAdd.count == 1)
        #expect(result.duplicateCount == 1)
    }

    @Test func deduplicatesOnISBNIgnoringFormatting() throws {
        let existing = [Book(title: "Old Title", author: "Old Author", isbn: "978-0-593-13520-4")]
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            { "title": "Different Title", "author": "Different Author", "isbn": "9780593135204" }
          ]
        }
        """), existingBooks: existing)

        #expect(result.toAdd.isEmpty)
        #expect(result.duplicateCount == 1)
    }

    @Test func deduplicatesOnISBNWithinTheFile() throws {
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            { "title": "A", "isbn": "123456789X" },
            { "title": "B", "isbn": "123456789x" }
          ]
        }
        """), existingBooks: [])

        #expect(result.toAdd.map(\.title) == ["A"])
        #expect(result.duplicateCount == 1)
    }

    @Test func throwsOnInvalidJSON() {
        #expect(throws: ImportParser.ImportError.self) {
            try ImportParser.parse(data("not json at all"), existingBooks: [])
        }
    }

    @Test func throwsWhenTitleMissing() {
        #expect(throws: ImportParser.ImportError.self) {
            try ImportParser.parse(data("""
            { "schemaVersion": 1, "books": [ { "author": "No Title" } ] }
            """), existingBooks: [])
        }
    }

    @Test func throwsOnUnsupportedVersion() {
        #expect(throws: ImportParser.ImportError.self) {
            try ImportParser.parse(data("""
            { "schemaVersion": 2, "books": [] }
            """), existingBooks: [])
        }
    }
}
