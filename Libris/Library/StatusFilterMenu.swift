//
//  StatusFilterMenu.swift
//  Libris
//

import SwiftUI

struct StatusFilterMenu: View {
    @Binding var selection: Set<BookStatus?>
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Text(currentLabel)
        }
        .help("Filter by reading status")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(BookStatus.allCases) { status in
                    Toggle(status.label, isOn: binding(for: status))
                }
                Toggle((nil as BookStatus?).facetLabel, isOn: binding(for: nil))

                Divider()

                Text("Presets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    ForEach(StatusPreset.allCases, id: \.self) { preset in
                        Button(preset.label) { selection = preset.statuses }
                    }
                }
            }
            .toggleStyle(.checkbox)
            .padding()
            .frame(minWidth: 220, alignment: .leading)
        }
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
