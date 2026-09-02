//
//  GenreFilterMenu.swift
//  Libris
//

import SwiftUI

struct GenreFilterMenu: View {
    @Binding var selection: Set<String>
    let availableGenres: [String]

    var body: some View {
        Menu(currentLabel) {
            ForEach(availableGenres, id: \.self) { genre in
                Toggle(genre, isOn: binding(for: genre))
            }

            Section("Presets") {
                Button("Fiction") { selection = fictionGenres }
                    .disabled(fictionGenres.isEmpty)
                Button("Non-Fiction") { selection = nonFictionGenres }
                    .disabled(nonFictionGenres.isEmpty)
            }
        }
        .help("Filter by genre")
    }

    private var currentLabel: String {
        if selection.count == 1, let only = selection.first { return only }
        return "Genre"
    }

    private func binding(for genre: String) -> Binding<Bool> {
        Binding(
            get: { selection.contains(genre) },
            set: { isOn in
                if isOn {
                    selection.insert(genre)
                } else {
                    selection.remove(genre)
                }
            }
        )
    }

    // A preset is disabled when its side is empty, so applying it can't leave an
    // empty selection (which would read as "all genres").
    private var fictionGenres: Set<String> { genres(fiction: true) }
    private var nonFictionGenres: Set<String> { genres(fiction: false) }

    private func genres(fiction: Bool) -> Set<String> {
        Set(availableGenres.filter { Self.isFiction($0) == fiction })
    }

    private static let fictionMarkers = [
        "novel", "novella", "fantasy", "science fiction", "mystery", "thriller",
        "romance", "horror"
    ]

    private static func isFiction(_ genre: String) -> Bool {
        let name = genre.lowercased()
        return fictionMarkers.contains { name.contains($0) }
    }
}
