//
//  LibraryFile.swift
//  Libris
//

import Foundation

/// The on-disk shape of a Libris library file: a version envelope wrapping the
/// book records it holds. Used for both import and export.
struct LibraryFile: Codable {
    var schemaVersion: Int
    var records: [BookRecord]

    /// Set to `backupKind` on exported files, so import can tell a full backup
    /// from a plain list of books to add.
    var kind: String?

    static let backupKind = "backup"

    /// The records live under the `books` key on disk; keep that key stable so
    /// existing library files stay readable while the Swift property name says
    /// what it actually holds.
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case records = "books"
        case kind
    }
}
