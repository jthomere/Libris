//
//  StatusPresetTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct StatusPresetTests {

    @Test func keepingIsEverythingExceptNotInterested() {
        let expected = Set(BookStatus.allCases.map(Optional.some) + [nil]).subtracting([.notInterested])
        #expect(StatusPreset.keeping.statuses == expected)
        #expect(!StatusPreset.keeping.statuses.contains(.notInterested))
    }

    @Test func interestedIsToReadNotSureAndDidNotFinish() {
        #expect(StatusPreset.interested.statuses == [.toRead, .notSure, .didNotFinish])
    }

    @Test func noStatusIsOnlyTheNilFacet() {
        #expect(StatusPreset.noStatus.statuses == [nil])
    }
}
