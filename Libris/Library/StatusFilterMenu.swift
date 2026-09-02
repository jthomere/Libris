//
//  StatusFilterMenu.swift
//  Libris
//

import SwiftUI

struct StatusFilterMenu: View {
    @Binding var selection: Set<BookStatus?>

    var body: some View {
        Menu(currentLabel) {
            ForEach(BookStatus.allCases) { status in
                Toggle(status.label, isOn: binding(for: status))
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
