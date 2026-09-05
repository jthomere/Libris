//
//  BookStatusTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct BookStatusTests {

    @Test func toggleSetsStatusFromNone() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        #expect(book.status == nil)

        book.toggleStatus(.toRead)
        #expect(book.status == .toRead)
    }

    @Test func toggleSameStatusClearsToNone() {
        let book = Book(title: "Dune", author: "Frank Herbert", status: .read)
        book.toggleStatus(.read)
        #expect(book.status == nil)
    }

    @Test func toggleDifferentStatusReplacesRatherThanResets() {
        let book = Book(title: "Dune", author: "Frank Herbert", status: .toRead)
        book.toggleStatus(.read)
        #expect(book.status == .read)
    }

    @Test func statusFallsBackToNoneForUnknownRawValue() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        book.statusRaw = "from-a-future-schema"
        #expect(book.status == nil)
    }

    @Test func settingStatusWritesRawValue() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        book.status = .notInterested
        #expect(book.statusRaw == "notInterested")
    }

    @Test func actionableListsEveryStatus() {
        #expect(BookStatus.actionable == [.toRead, .read, .didNotFinish, .notSure, .gaveUp, .notInterested])
        #expect(Set(BookStatus.actionable) == Set(BookStatus.allCases))
    }
}
