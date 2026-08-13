//
//  LibraryExporterTests.swift
//  LibrisTests
//

import Foundation
import Testing
@testable import Libris

struct LibraryExporterTests {

    @Test func roundTripsBooksThroughExportAndImport() throws {
        let original = [
            Book(
                title: "Project Hail Mary",
                author: "Andy Weir",
                isbn: "9780593135204",
                genre: "Science Fiction",
                rating: 4.5,
                note: "Loved it",
                tags: ["SF", "Staff Pick"],
                status: .read,
                dateAdded: Date(timeIntervalSince1970: 1_600_000_000)
            ),
            Book(
                title: "Bare",
                status: .toRead,
                dateAdded: Date(timeIntervalSince1970: 1_610_000_000)
            )
        ]

        let data = try LibraryExporter.export(original)
        let parsed = try ImportParser.parse(data, existingBooks: [])

        #expect(parsed.isBackup)
        #expect(parsed.duplicateCount == 0)
        #expect(parsed.toAdd.count == 2)

        let byTitle = Dictionary(uniqueKeysWithValues: parsed.toAdd.map { ($0.title, $0) })

        let phm = try #require(byTitle["Project Hail Mary"])
        #expect(phm.author == "Andy Weir")
        #expect(phm.isbn == "9780593135204")
        #expect(phm.genre == "Science Fiction")
        #expect(phm.rating == 4.5)
        #expect(phm.note == "Loved it")
        #expect(phm.tags == ["SF", "Staff Pick"])
        #expect(phm.status == .read)
        #expect(phm.dateAdded == Date(timeIntervalSince1970: 1_600_000_000))

        let bare = try #require(byTitle["Bare"])
        #expect(bare.author == "")
        #expect(bare.tags == [])
        #expect(bare.status == .toRead)
        #expect(bare.dateAdded == Date(timeIntervalSince1970: 1_610_000_000))
    }

    @Test @MainActor func exportedFileIsMarkedAsBackup() throws {
        let data = try LibraryExporter.export([Book(title: "One")])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file = try decoder.decode(LibraryFile.self, from: data)

        #expect(file.schemaVersion == ImportParser.supportedVersion)
        #expect(file.kind == LibraryFile.backupKind)
        #expect(file.books.count == 1)
    }
}
