//
//  BookFilter.swift
//  Libris
//

import Foundation

enum BookFilter {
    static func filter(_ books: [Book], searchText: String, status: BookStatus?, genre: String?, hideToRemove: Bool) -> [Book] {
        let query = searchText.whitespaceTrimmed.lowercased()
        return books.filter { book in
            if let status {
                if book.status != status { return false }
            } else if hideToRemove && book.status == .toRemove {
                return false
            }
            if let genre, book.genre != genre { return false }
            if !query.isEmpty {
                let matchesTitle = book.title.lowercased().contains(query)
                let matchesAuthor = book.author.lowercased().contains(query)
                if !matchesTitle && !matchesAuthor { return false }
            }
            return true
        }
    }
}
