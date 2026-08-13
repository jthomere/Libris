//
//  LibraryDateCoding.swift
//  Libris
//

import Foundation

/// Matching JSON date strategies for library files. Dates are written as ISO
/// 8601 with fractional seconds so a backup restores exactly; reading also
/// accepts whole-second strings from older files.
enum LibraryDateCoding {
    static var encoding: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
        }
    }

    static var decoding: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            if let date = try? Date(string, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
                return date
            }
            if let date = try? Date(string, strategy: Date.ISO8601FormatStyle()) {
                return date
            }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid ISO 8601 date: \(string)")
            )
        }
    }
}
