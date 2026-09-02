//
//  StatusFilterMenu.swift
//  Libris
//

import SwiftUI

struct StatusFilterMenu: View {
    @Binding var selection: Set<BookStatus?>

    private let allFacets: [BookStatus?] = BookStatus.allCases.map(Optional.some) + [nil]

    var body: some View {
        Menu(currentLabel) {
            ForEach(allFacets, id: \.self) { facet in
                Toggle(facet.facetLabel, isOn: binding(for: facet))
            }

            Section("Presets") {
                ForEach(StatusPreset.allCases, id: \.self) { preset in
                    Button(preset.label) { selection = preset.statuses }
                }
            }
        }
        .help("Filter by reading status")
    }

    private var currentLabel: String {
        if selection.count == 1, let only = selection.first { return only.facetLabel }
        return "Status"
    }

    private func binding(for facet: BookStatus?) -> Binding<Bool> {
        Binding(
            get: { selection.contains(facet) },
            set: { isOn in
                if isOn {
                    selection.insert(facet)
                } else {
                    selection.remove(facet)
                }
            }
        )
    }
}
