//
//  BookSection.swift
//  Libris
//

import Foundation

/// A titled run of books shown as one section, with a pinned header, in the
/// library grid. Built by `BookSort.sections(from:)`.
struct BookSection: Identifiable {
    let id: String
    let title: String
    var books: [Book]
}
