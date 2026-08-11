//
//  FilterBarView.swift
//  Libris
//

import SwiftUI

struct FilterBarView: View {
    @Binding var searchText: String
    @Binding var statusFilter: BookStatus?
    @Binding var genreFilter: String?
    @Binding var includeToRemove: Bool
    let availableGenres: [String]

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

            Picker("Status", selection: $statusFilter) {
                Text("All Statuses").tag(BookStatus?.none)
                ForEach(BookStatus.allCases) { status in
                    Text(status.label).tag(BookStatus?.some(status))
                }
            }
            .frame(maxWidth: 180)

            Picker("Genre", selection: $genreFilter) {
                Text("All Genres").tag(String?.none)
                ForEach(availableGenres, id: \.self) { genre in
                    Text(genre).tag(String?.some(genre))
                }
            }
            .frame(maxWidth: 180)

            Toggle("Include books to remove", isOn: $includeToRemove)

            Spacer()
        }
        .padding(12)
    }
}
