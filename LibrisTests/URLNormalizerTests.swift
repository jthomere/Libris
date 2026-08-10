//
//  URLNormalizerTests.swift
//  LibrisTests
//

import Testing
import Foundation
@testable import Libris

struct URLNormalizerTests {

    @Test func emptyOrWhitespaceReturnsNil() {
        #expect(URLNormalizer.normalized(from: "") == nil)
        #expect(URLNormalizer.normalized(from: "   ") == nil)
    }

    @Test func schemedURLsPassThroughUnchanged() {
        #expect(URLNormalizer.normalized(from: "https://example.com")?.absoluteString == "https://example.com")
        #expect(URLNormalizer.normalized(from: "http://example.com")?.scheme == "http")
        #expect(URLNormalizer.normalized(from: "mailto:a@b.com")?.scheme == "mailto")
    }

    @Test func schemeLessURLsGetHTTPS() {
        #expect(URLNormalizer.normalized(from: "www.goodreads.com/x")?.absoluteString == "https://www.goodreads.com/x")
        #expect(URLNormalizer.normalized(from: "covers.openlibrary.org/b/isbn/x-L.jpg")?.absoluteString == "https://covers.openlibrary.org/b/isbn/x-L.jpg")
        #expect(URLNormalizer.normalized(from: "www.goodreads.com/x")?.scheme == "https")
    }

    @Test func surroundingWhitespaceIsTrimmed() {
        #expect(URLNormalizer.normalized(from: "  https://example.com  ")?.absoluteString == "https://example.com")
    }
}
