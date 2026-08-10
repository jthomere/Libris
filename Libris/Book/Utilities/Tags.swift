//
//  Tags.swift
//  Libris
//

import Foundation

enum Tags {
    static func parse(_ string: String) -> [String] {
        string
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static func format(_ tags: [String]) -> String {
        tags.joined(separator: ", ")
    }
}
