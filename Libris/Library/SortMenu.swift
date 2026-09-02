//
//  SortMenu.swift
//  Libris
//

import SwiftUI

struct SortMenu: View {
    @Binding var sort: BookSort

    var body: some View {
        Menu {
            ForEach(BookSort.Key.allCases) { key in
                Button {
                    select(key)
                } label: {
                    if sort.key == key {
                        Label(key.label, systemImage: sort.ascending ? "chevron.up" : "chevron.down")
                    } else {
                        Text(key.label)
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    private func select(_ key: BookSort.Key) {
        if sort.key == key {
            sort.ascending.toggle()
        } else {
            sort = BookSort(key: key, ascending: key.startsAscending)
        }
    }
}
