//
//  SoftDeleteTests.swift
//  LibrisTests
//

import Foundation
import SwiftData
import Testing
@testable import Libris

@MainActor
struct SoftDeleteTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Book.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func activeBooks(in context: ModelContext) throws -> [Book] {
        try context.fetch(FetchDescriptor<Book>(predicate: #Predicate { $0.deletedDate == nil }))
    }

    private func deletedBooks(in context: ModelContext) throws -> [Book] {
        try context.fetch(FetchDescriptor<Book>(predicate: #Predicate { $0.deletedDate != nil }))
    }

    @Test func newBookIsNotDeleted() {
        #expect(Book(title: "Dune").isDeleted == false)
    }

    @Test func bookWithDeletedDateReportsDeleted() {
        #expect(Book(title: "Dune", deletedDate: Date()).isDeleted)
    }

    @Test func activeFetchExcludesDeleted() throws {
        let context = try makeContext()
        context.insert(Book(title: "Keep"))
        context.insert(Book(title: "Deleted", deletedDate: Date()))

        #expect(try activeBooks(in: context).map(\.title) == ["Keep"])
        #expect(try deletedBooks(in: context).map(\.title) == ["Deleted"])
    }

    @Test func restoringReturnsBookToActive() throws {
        let context = try makeContext()
        let book = Book(title: "Dune", deletedDate: Date())
        context.insert(book)

        book.deletedDate = nil

        #expect(try activeBooks(in: context).map(\.title) == ["Dune"])
        #expect(try deletedBooks(in: context).isEmpty)
    }

    /// A deleted book is treated as not present: import dedupe runs against the
    /// active books, so an incoming copy of a deleted book is re-added.
    @Test func deletedBookDoesNotBlockReimport() throws {
        let context = try makeContext()
        context.insert(Book(title: "Dune", author: "Frank Herbert", deletedDate: Date()))

        let tracker = DuplicateTracker(existingBooks: try activeBooks(in: context))
        #expect(tracker.isDuplicate(title: "Dune", author: "Frank Herbert", isbn: "") == false)
    }
}
