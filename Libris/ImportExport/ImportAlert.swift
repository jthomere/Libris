//
//  ImportAlert.swift
//  Libris
//

import Foundation

/// The result of an import attempt, shaped into the title and message shown in
/// the post-import alert: either a summary of what was added and skipped, or a
/// failure with its reason.
enum ImportAlert: Identifiable {
    case summary(added: Int, duplicates: Int)
    case failure(message: String)

    var id: String {
        switch self {
        case .summary(let added, let duplicates): return "summary-\(added)-\(duplicates)"
        case .failure(let message): return "failure-\(message)"
        }
    }

    var title: String {
        switch self {
        case .summary(let added, _): return added == 0 ? "No New Books" : "Books Imported"
        case .failure: return "Import Failed"
        }
    }

    var message: String {
        switch self {
        case .summary(let added, let duplicates):
            var parts = [added == 1 ? "Added 1 book." : "Added \(added) books."]
            if duplicates > 0 {
                parts.append(duplicates == 1
                    ? "Skipped 1 duplicate."
                    : "Skipped \(duplicates) duplicates.")
            }
            return parts.joined(separator: " ")
        case .failure(let message):
            return message
        }
    }
}
