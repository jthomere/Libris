//
//  AIPromptTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct AIPromptTests {

    @Test func includesSchemaVersionAndFieldNames() {
        let text = AIPrompt.text(genres: [], tags: [])
        #expect(text.contains("\"schemaVersion\": \(ImportParser.latestVersion)"))
        #expect(text.contains("\"title\""))
        #expect(text.contains("bookDescription"))
        #expect(text.contains("coverImageURL"))
    }

    @Test func listsProvidedGenres() {
        let text = AIPrompt.text(genres: ["Fantasy", "Science Fiction"], tags: [])
        #expect(text.contains("Fantasy, Science Fiction"))
    }

    @Test func omitsGenreSectionWhenEmpty() {
        let text = AIPrompt.text(genres: [], tags: [])
        #expect(!text.contains("Genres already in my library"))
    }

    @Test func listsProvidedTags() {
        let text = AIPrompt.text(genres: [], tags: ["Bestseller", "Staff Pick"])
        #expect(text.contains("Bestseller, Staff Pick"))
    }
}
