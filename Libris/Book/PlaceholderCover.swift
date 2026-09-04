//
//  PlaceholderCover.swift
//  Libris
//
//  A generated "cover" for books without a cover image: title and author set
//  typographically over a vibrant, per-book gradient.
//

import SwiftUI

struct PlaceholderCover: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Futura-CondensedExtraBold", size: 34))
                .lineLimit(6)
                .minimumScaleFactor(0.45)
            Spacer(minLength: 8)
            Text(author)
                .font(.custom("Futura-Medium", size: 15))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(gradient)
    }

    private var title: String { book.title.isEmpty ? "Untitled" : book.title }
    private var author: String { book.author.isEmpty ? "Unknown author" : book.author }

    /// A diagonal gradient with a random-looking (but stable) per-book hue and
    /// a saturation keyed to status: engaged statuses are vivid, dismissed
    /// ones drab.
    private var gradient: LinearGradient {
        let h = hue
        let s = saturation
        return LinearGradient(
            colors: [
                Color(hue: h, saturation: s, brightness: 0.85),
                Color(hue: (h + 0.08).truncatingRemainder(dividingBy: 1), saturation: min(s + 0.12, 1), brightness: 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// A stable 0–1 hue from title + author (djb2), so each book gets its own
    /// color that survives relaunches and doesn't flicker while scrolling.
    private var hue: Double {
        var hash: UInt64 = 5381
        for byte in "\(title)|\(author)".utf8 { hash = (hash &* 33) ^ UInt64(byte) }
        return Double(hash % 360) / 360.0
    }

    /// How vivid the cover is, from anticipation (To Read) down to dismissal
    /// (Not Interested).
    private var saturation: Double {
        switch book.status {
        case .toRead:        return 0.85
        case .read:          return 0.70
        case .notSure:       return 0.55
        case .didNotFinish:  return 0.42
        case .gaveUp:        return 0.32
        case .notInterested: return 0.15
        case nil:            return 0.55
        }
    }
}
