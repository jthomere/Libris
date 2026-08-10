//
//  BookStatusTests.swift
//  LibrisTests
//

import Testing
@testable import Libris

struct BookStatusTests {

    @Test func toggleSetsStatusFromUnsorted() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        #expect(book.status == .unsorted)

        book.toggleStatus(.toRead)
        #expect(book.status == .toRead)
    }

    @Test func toggleSameStatusResetsToUnsorted() {
        let book = Book(title: "Dune", author: "Frank Herbert", status: .read)
        book.toggleStatus(.read)
        #expect(book.status == .unsorted)
    }

    @Test func toggleDifferentStatusReplacesRatherThanResets() {
        let book = Book(title: "Dune", author: "Frank Herbert", status: .toRead)
        book.toggleStatus(.read)
        #expect(book.status == .read)
    }

    @Test func statusFallsBackToUnsortedForUnknownRawValue() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        book.statusRaw = "from-a-future-schema"
        #expect(book.status == .unsorted)
    }

    @Test func settingStatusWritesRawValue() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        book.status = .toRemove
        #expect(book.statusRaw == "toRemove")
    }

    @Test func actionableExcludesUnsorted() {
        #expect(BookStatus.actionable == [.toRead, .read, .toRemove])
        #expect(!BookStatus.actionable.contains(.unsorted))
    }
}
