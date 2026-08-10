//
//  StarRatingView.swift
//  Libris
//

import SwiftUI

/// A 0–5 star rating control. When `isEditable`, clicking a star sets that
/// rating; clicking the leftmost star when the rating is already 1 clears it to
/// 0. When not editable, it's a read-only display of the current rating.
struct StarRatingView: View {
    @Binding var rating: Double
    var isEditable: Bool = true

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: Double(index) <= rating.rounded() ? "star.fill" : "star")
                    .foregroundStyle(.yellow)
                    .onTapGesture {
                        guard isEditable else { return }
                        let value = Double(index)
                        rating = (rating == value) ? value - 1 : value
                    }
            }
            if isEditable && rating > 0 {
                Button {
                    rating = 0
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear rating")
            }
        }
    }
}
