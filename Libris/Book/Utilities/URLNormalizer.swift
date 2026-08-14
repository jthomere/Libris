//
//  URLNormalizer.swift
//  Libris
//

import Foundation

enum URLNormalizer {
    static func normalized(from string: String) -> URL? {
        let trimmed = string.whitespaceTrimmed
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }
}
