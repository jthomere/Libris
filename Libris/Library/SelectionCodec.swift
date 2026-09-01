//
//  SelectionCodec.swift
//  Libris
//

import Foundation

/// Encodes a set of string tokens as a JSON array so multi-select filters can
/// persist via `@AppStorage` without worrying about separators appearing inside
/// the values (e.g. a genre containing a comma).
enum SelectionCodec {
    static func encode<S: Sequence>(_ values: S) -> String where S.Element == String {
        guard let data = try? JSONEncoder().encode(Array(values).sorted()),
              let string = String(data: data, encoding: .utf8) else { return "" }
        return string
    }

    /// Returns the decoded tokens, or `nil` when the string isn't valid JSON —
    /// letting callers tell a genuine empty selection (`"[]"`) apart from a
    /// stale or corrupt value, which should fall back to a default.
    static func decode(_ string: String) -> [String]? {
        guard let data = string.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        return values
    }
}
