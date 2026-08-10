//
//  StarRatingView.swift
//  Libris
//

import SwiftUI

/// A clickable 0–5 star rating control. Clicking a star sets that rating;
/// clicking the leftmost star when the rating is already 1 clears it to 0.
struct StarRatingView: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: Double(index) <= rating.rounded() ? "star.fill" : "star")
                    .foregroundStyle(.yellow)
                    .onTapGesture {
                        let value = Double(index)
                        rating = (rating == value) ? value - 1 : value
                    }
            }
            if rating > 0 {
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
