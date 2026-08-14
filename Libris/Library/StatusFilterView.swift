//
//  StatusFilterView.swift
//  Libris
//

import SwiftUI

struct StatusFilterView: View {
    let books: [Book]
    @Binding var visibleStatuses: Set<BookStatus>

    // Split the statuses across two rows chosen so the rows come out roughly
    // the same length. The "All" chip leads the first row.
    private let firstRowStatuses: [BookStatus] = [.unsorted, .toRead, .gaveUp, .read]
    private let secondRowStatuses: [BookStatus] = [.notSure, .didNotFinish, .toRemove]

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // A single row when the window is wide enough; otherwise fall back
            // to the two balanced rows.
            ViewThatFits(in: .horizontal) {
                singleRow
                twoRows
            }
            presetMenu
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var singleRow: some View {
        HStack(spacing: 10) {
            ForEach(BookStatus.allCases) { status in
                statusToggle(status)
            }
        }
    }

    private var twoRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ForEach(firstRowStatuses) { status in
                    statusToggle(status)
                }
            }
            HStack(spacing: 10) {
                ForEach(secondRowStatuses) { status in
                    statusToggle(status)
                }
            }
        }
    }

    /// Applies a named preset; its title shows the current one, or "Custom"
    /// when the selection matches no preset.
    private var presetMenu: some View {
        Menu(StatusPreset.matching(visibleStatuses)?.label ?? "Custom") {
            ForEach(StatusPreset.allCases, id: \.self) { preset in
                Button(preset.label) { visibleStatuses = preset.statuses }
            }
        }
        .fixedSize()
    }

    /// A stateful toggle for whether books with `status` are shown.
    private func statusToggle(_ status: BookStatus) -> some View {
        Toggle(isOn: binding(for: status)) {
            label(status.label, count: count(for: status), systemImage: status.systemImage)
        }
        .toggleStyle(StatusToggleStyle(tint: status.tint))
    }

    private func label(_ text: String, count: Int, systemImage: String) -> some View {
        Label {
            Text("\(text) \(Text("\(count)").fontWeight(.semibold).monospacedDigit())")
        } icon: {
            Image(systemName: systemImage)
        }
        .lineLimit(1)
        .fixedSize()
    }

    private func binding(for status: BookStatus) -> Binding<Bool> {
        Binding(
            get: { visibleStatuses.contains(status) },
            set: { isShown in
                if isShown {
                    visibleStatuses.insert(status)
                } else {
                    visibleStatuses.remove(status)
                }
            }
        )
    }

    private func count(for status: BookStatus) -> Int {
        books.filter { $0.status == status }.count
    }
}
