//
//  BookSection.swift
//  Libris
//

import Foundation

struct BookSection: Identifiable {
    let id: String
    let title: String
    var books: [Book]
}
