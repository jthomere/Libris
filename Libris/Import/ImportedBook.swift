//
//  ImportedBook.swift
//  Libris
//

import Foundation

/// One book as it appears in an import file. JSON keys match these property
/// names exactly, so no `CodingKeys` mapping is needed. Only `title` is
/// required; every other field is optional and defaulted when building a
/// `Book`.
struct ImportedBook: Decodable {
    var title: String
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
}
