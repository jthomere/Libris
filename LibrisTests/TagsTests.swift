//
//  TagsTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct TagsTests {

    @Test func parseSplitsTrimsAndDropsEmpties() {
        #expect(Tags.parse("Staff Pick, Bestseller") == ["Staff Pick", "Bestseller"])
        #expect(Tags.parse("a,,b") == ["a", "b"])
        #expect(Tags.parse("a, ") == ["a"])
        #expect(Tags.parse("   ") == [])
        #expect(Tags.parse("") == [])
    }

    @Test func formatJoinsWithCommaSpace() {
        #expect(Tags.format(["a", "b"]) == "a, b")
        #expect(Tags.format([]) == "")
    }

    @Test func parseFormatRoundTrips() {
        let tags = ["Staff Pick", "Bestseller", "Award Winner"]
        #expect(Tags.parse(Tags.format(tags)) == tags)
    }
}
