//
//  SortMenu.swift
//  Libris
//

import SwiftUI

struct SortMenu: View {
    @Binding var sort: BookSort
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label(sort.key.label, systemImage: sort.ascending ? "arrow.up" : "arrow.down")
                .labelStyle(.titleAndIcon)
        }
        .help("Sort the library")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sort by")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Sort by", selection: keyBinding) {
                    ForEach(BookSort.Key.allCases) { key in
                        Text(key.label).tag(key)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                Divider()

                Text("Order")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Order", selection: $sort.ascending) {
                    Text("Ascending").tag(true)
                    Text("Descending").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding()
            .frame(minWidth: 220, alignment: .leading)
        }
    }

    // Switching keys adopts that key's natural direction (A→Z, newest first, …);
    // the Order control can then override it.
    private var keyBinding: Binding<BookSort.Key> {
        Binding(
            get: { sort.key },
            set: { newKey in
                guard newKey != sort.key else { return }
                sort = BookSort(key: newKey, ascending: newKey.startsAscending)
            }
        )
    }
}
