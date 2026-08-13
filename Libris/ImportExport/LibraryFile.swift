//
//  LibraryFile.swift
//  Libris
//

import Foundation

/// The on-disk shape of a Libris library file: a version envelope wrapping the
/// books it holds. Used for both import and export.
struct LibraryFile: Codable {
    var schemaVersion: Int
    var books: [BookRecord]

    /// Set to `backupKind` on exported files, so import can tell a full backup
    /// from a plain list of books to add.
    var kind: String?

    static let backupKind = "backup"
}
