//
//  CountsBarView.swift
//  Libris
//

import SwiftUI

struct CountsBarView: View {
    let books: [Book]
    @Binding var statusFilter: BookStatus?
    @Binding var hideToRemove: Bool

    // Split the statuses across two rows chosen so the rows come out roughly
    // the same length. The "All" chip leads the first row and the toggle ends
    // the second.
    private let firstRowStatuses: [BookStatus] = [.unsorted, .toRead, .gaveUp, .read]
    private let secondRowStatuses: [BookStatus] = [.notSure, .didNotFinish, .toRemove]

    var body: some View {
        // A single row when the window is wide enough; otherwise fall back to
        // the two balanced rows.
        ViewThatFits(in: .horizontal) {
            singleRow
            twoRows
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var singleRow: some View {
        HStack(spacing: 10) {
            allChip
            ForEach(BookStatus.allCases) { status in
                statusChip(status)
            }
            hideToRemoveToggle
        }
    }

    private var twoRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                allChip
                ForEach(firstRowStatuses) { status in
                    statusChip(status)
                }
            }
            HStack(spacing: 10) {
                ForEach(secondRowStatuses) { status in
                    statusChip(status)
                }
                hideToRemoveToggle
            }
        }
    }

    private var allChip: some View {
        countChip(label: "All", count: books.count, image: "books.vertical", status: nil)
    }

    private var hideToRemoveToggle: some View {
        Toggle("Hide To Remove", isOn: $hideToRemove)
            .fixedSize()
    }

    private func statusChip(_ status: BookStatus) -> some View {
        countChip(label: status.label, count: count(for: status), image: status.systemImage, status: status)
    }

    private func countChip(label: String, count: Int, image: String, status: BookStatus?) -> some View {
        let isActive = statusFilter == status
        return Button {
            if let status {
                statusFilter = (statusFilter == status) ? nil : status
            } else {
                statusFilter = nil
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: image)
                Text(label)
                    .lineLimit(1)
                    .fixedSize()
                Text("\(count)")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .font(.callout)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary), in: Capsule())
            .foregroundStyle(isActive ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private func count(for status: BookStatus) -> Int {
        books.filter { $0.status == status }.count
    }
}
