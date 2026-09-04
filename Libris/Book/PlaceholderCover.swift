//
//  PlaceholderCover.swift
//  Libris
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
        .background(backgroundGradient)
    }

    private var title: String { book.title.isEmpty ? "Untitled" : book.title }
    private var author: String { book.author.isEmpty ? "Unknown author" : book.author }

    private var backgroundGradient: LinearGradient {
        let hue = coverHue
        let saturation = statusSaturation
        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: saturation, brightness: 0.85),
                Color(hue: (hue + 0.08).truncatingRemainder(dividingBy: 1), saturation: min(saturation + 0.12, 1), brightness: 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var coverHue: Double {
        var hash: UInt64 = 5381
        for byte in "\(title)|\(author)".utf8 { hash = (hash &* 33) ^ UInt64(byte) }
        return Double(hash % 360) / 360.0
    }

    private var statusSaturation: Double {
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
