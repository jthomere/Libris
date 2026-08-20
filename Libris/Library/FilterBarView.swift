//
//  FilterBarView.swift
//  Libris
//

import SwiftUI

struct FilterBarView: View {
    @Binding var searchText: String
    @Binding var genreFilter: String?
    let availableGenres: [String]
    @Binding var showingRecentlyAdded: Bool
    let recentlyAddedCount: Int

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search title or author", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 320)

            Picker("Genre", selection: $genreFilter) {
                Text("All Genres").tag(String?.none)
                ForEach(availableGenres, id: \.self) { genre in
                    Text(genre).tag(String?.some(genre))
                }
            }
            .frame(maxWidth: 180)

            Toggle(isOn: $showingRecentlyAdded) {
                Label("Recently Added", systemImage: "clock.arrow.circlepath")
            }
            .toggleStyle(.button)
            .disabled(recentlyAddedCount == 0)
            .help("Show only the most recently added books")

            Spacer()
        }
        .padding(12)
    }
}
