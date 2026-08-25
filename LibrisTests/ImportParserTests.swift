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
        #expect(book.status == nil)
    }

    @Test func datelessImportedBooksShareOneDateAdded() throws {
        let result = try ImportParser.parse(data("""
        { "schemaVersion": 1, "books": [ { "title": "A" }, { "title": "B" } ] }
        """), existingBooks: [])

        #expect(result.toAdd.count == 2)
        #expect(result.toAdd[0].dateAdded == result.toAdd[1].dateAdded)
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

    @Test func parsesStatusAndDateAdded() throws {
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            { "title": "Finished", "status": "read", "dateAdded": "2021-03-04T05:06:07Z" }
          ]
        }
        """), existingBooks: [])

        let book = try #require(result.toAdd.first)
        #expect(book.status == .read)
        #expect(book.dateAdded == ISO8601DateFormatter().date(from: "2021-03-04T05:06:07Z"))
    }

    @Test func unknownOrMissingStatusFallsBackToNone() throws {
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            { "title": "Garbage", "status": "banana" },
            { "title": "None" }
          ]
        }
        """), existingBooks: [])

        #expect(result.toAdd[0].status == nil)
        #expect(result.toAdd[1].status == nil)
    }

    @Test func detectsBackupMarker() throws {
        let result = try ImportParser.parse(data("""
        { "schemaVersion": 1, "kind": "backup", "books": [ { "title": "A" }, { "title": "B" } ] }
        """), existingBooks: [])

        #expect(result.isBackup)
        #expect(result.fileBookCount == 2)
    }

    @Test func regularImportIsNotABackup() throws {
        let result = try ImportParser.parse(data("""
        { "schemaVersion": 1, "books": [ { "title": "A" } ] }
        """), existingBooks: [])

        #expect(result.isBackup == false)
    }

    @Test func fileBookCountIncludesDuplicates() throws {
        let existing = [Book(title: "Dune", author: "Frank Herbert")]
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 1,
          "books": [
            { "title": "Dune", "author": "Frank Herbert" },
            { "title": "New" }
          ]
        }
        """), existingBooks: existing)

        #expect(result.toAdd.count == 1)
        #expect(result.duplicateCount == 1)
        #expect(result.fileBookCount == 2)
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

    @Test func missingTitleImportsAsUntitled() throws {
        let result = try ImportParser.parse(data("""
        { "schemaVersion": 1, "books": [ { "author": "No Title" } ] }
        """), existingBooks: [])

        #expect(result.toAdd.map(\.title) == [""])
        #expect(result.toAdd.first?.author == "No Title")
    }

    @Test func throwsOnUnsupportedVersion() {
        #expect(throws: ImportParser.ImportError.self) {
            try ImportParser.parse(data("""
            { "schemaVersion": 3, "books": [] }
            """), existingBooks: [])
        }
    }

    @Test func acceptsLegacyVersionOneFiles() throws {
        let result = try ImportParser.parse(data("""
        { "schemaVersion": 1, "books": [ { "title": "Legacy" } ] }
        """), existingBooks: [])

        #expect(result.toAdd.map(\.title) == ["Legacy"])
        #expect(result.isBackup == false)
    }

    @Test func backupPreservesBlankTitleBooks() throws {
        let result = try ImportParser.parse(data("""
        {
          "schemaVersion": 2,
          "kind": "backup",
          "books": [
            { "title": "", "author": "Ghost", "status": "read" },
            { "title": "   ", "author": "" },
            { "title": "Real", "author": "Someone" }
          ]
        }
        """), existingBooks: [])

        #expect(result.isBackup)
        #expect(result.toAdd.count == 3)
        #expect(result.fileBookCount == 3)
        #expect(result.toAdd.filter { $0.title.isEmpty }.count == 2)
        #expect(result.toAdd.contains { $0.title.isEmpty && $0.author == "Ghost" && $0.status == .read })
    }
}
