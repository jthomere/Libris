//
//  SelectionCodec.swift
//  Libris
//

import Foundation

// JSON, rather than a separator-joined string, so values containing commas
// (e.g. a genre name) round-trip safely.
enum SelectionCodec {
    static func encode<S: Sequence>(_ values: S) -> String where S.Element == String {
        guard let data = try? JSONEncoder().encode(Array(values).sorted()),
              let string = String(data: data, encoding: .utf8) else { return "" }
        return string
    }

    // nil on invalid JSON, so callers can tell a real empty selection ("[]")
    // from a stale value that should fall back to a default.
    static func decode(_ string: String) -> [String]? {
        guard let data = string.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        return values
    }
}
