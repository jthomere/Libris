//
//  CountsBarView.swift
//  Libris
//

import SwiftUI

struct CountsBarView: View {
    let books: [Book]
    let filteredCount: Int
    let isFiltering: Bool

    var body: some View {
        HStack(spacing: 10) {
            countChip(label: "Total", count: books.count, image: "books.vertical")
            ForEach(BookStatus.allCases) { status in
                countChip(
                    label: status.label,
                    count: count(for: status),
                    image: status.systemImage
                )
            }
            Spacer()
            if isFiltering {
                Text("\(filteredCount) shown")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func countChip(label: String, count: Int, image: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: image)
            Text(label)
            Text("\(count)")
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.callout)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.quaternary, in: Capsule())
    }

    private func count(for status: BookStatus) -> Int {
        books.filter { $0.status == status }.count
    }
}
