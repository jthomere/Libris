//
//  String+Whitespace.swift
//  Libris
//

import Foundation

extension String {
    /// The string with leading and trailing whitespace and newlines removed.
    var whitespaceTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `true` when the string is empty or only whitespace and newlines.
    var isBlank: Bool {
        whitespaceTrimmed.isEmpty
    }
}
