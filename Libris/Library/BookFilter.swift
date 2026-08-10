//
//  BookFilter.swift
//  Libris
//

import Foundation

enum BookFilter {
    static func filter(_ books: [Book], searchText: String, status: BookStatus?, genre: String?) -> [Book] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return books.filter { book in
            if let status, book.status != status { return false }
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
