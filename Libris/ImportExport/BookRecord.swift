//
//  BookRecord.swift
//  Libris
//

import Foundation

/// One book as stored in a Libris library file.
struct BookRecord: Codable {
    var title: String?
    var author: String?
    var isbn: String?
    var bookDescription: String?
    var genre: String?
    var rating: Double?
    var note: String?
    var tags: [String]?
    var goodreadsURL: String?
    var amazonURL: String?
    var coverImageURL: String?
    var status: String?
    var dateAdded: Date?
}
