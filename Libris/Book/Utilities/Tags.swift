//
//  Tags.swift
//  Libris
//

import Foundation

enum Tags {
    static func parse(_ string: String) -> [String] {
        string
            .split(separator: ",")
            .map { String($0).whitespaceTrimmed }
            .filter { !$0.isEmpty }
    }

    static func format(_ tags: [String]) -> String {
        tags.joined(separator: ", ")
    }
}
