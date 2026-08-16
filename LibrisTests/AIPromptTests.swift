//
//  AIPromptTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct AIPromptTests {

    @Test func includesSchemaVersionAndFieldNames() {
        let text = AIPrompt.text(genres: [])
        #expect(text.contains("\"schemaVersion\": \(ImportParser.latestVersion)"))
        #expect(text.contains("\"title\""))
        #expect(text.contains("bookDescription"))
        #expect(text.contains("coverImageURL"))
    }

    @Test func listsProvidedGenres() {
        let text = AIPrompt.text(genres: ["Fantasy", "Science Fiction"])
        #expect(text.contains("Fantasy, Science Fiction"))
    }

    @Test func omitsGenreSectionWhenEmpty() {
        let text = AIPrompt.text(genres: [])
        #expect(!text.contains("Genres already in my library"))
    }
}
