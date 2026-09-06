//
//  GenreFilterMenu.swift
//  Libris
//

import SwiftUI

struct GenreFilterMenu: View {
    @Binding var selection: Set<String>
    let availableGenres: [String]
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Text(currentLabel)
        }
        .help("Filter by genre")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(availableGenres, id: \.self) { genre in
                            Toggle(genre, isOn: binding(for: genre))
                        }
                        .toggleStyle(.checkbox)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)

                Divider()

                Text("Presets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Fiction") { selection = fictionGenres }
                        .disabled(fictionGenres.isEmpty)
                    Button("Non-Fiction") { selection = nonFictionGenres }
                        .disabled(nonFictionGenres.isEmpty)
                }
            }
            .padding()
            .frame(minWidth: 220, alignment: .leading)
        }
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
