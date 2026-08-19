//
//  FlowLayout.swift
//  Libris
//

import SwiftUI

/// A minimal flow layout that wraps its children onto multiple lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func makeCache(subviews: Subviews) -> [CGSize]? { nil }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout [CGSize]?) -> CGSize {
        Self.arrange(resolvedSizes(subviews: subviews, cache: &cache), spacing: spacing, maxWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout [CGSize]?) {
        let sizes = resolvedSizes(subviews: subviews, cache: &cache)
        let origins = Self.arrange(sizes, spacing: spacing, maxWidth: bounds.width).origins
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + origins[index].x, y: bounds.minY + origins[index].y),
                proposal: ProposedViewSize(sizes[index])
            )
        }
    }

    private func resolvedSizes(subviews: Subviews, cache: inout [CGSize]?) -> [CGSize] {
        if let sizes = cache, sizes.count == subviews.count { return sizes }
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        cache = sizes
        return sizes
    }

    /// Positions boxes of the given `sizes` into rows that wrap at `maxWidth`,
    /// returning each box's origin (relative to the top-left) and the overall
    /// size the rows occupy. Pure geometry, so it can be unit-tested directly.
    static func arrange(_ sizes: [CGSize], spacing: CGFloat, maxWidth: CGFloat) -> (origins: [CGPoint], size: CGSize) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for size in sizes {
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x - spacing)
        }

        return (origins, CGSize(width: min(totalWidth, maxWidth), height: y + rowHeight))
    }
}
