//
//  ImportFile.swift
//  Libris
//

import Foundation

/// The top-level shape of a Libris import file: a version envelope wrapping
/// the batch of books to add. Matches the format spec shared with the file
/// generator.
struct ImportFile: Decodable {
    var schemaVersion: Int
    var books: [ImportedBook]
}
