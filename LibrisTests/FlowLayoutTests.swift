//
//  FlowLayoutTests.swift
//  LibrisTests
//

import CoreGraphics
import Testing
@testable import Libris

struct FlowLayoutTests {

    private let box = CGSize(width: 100, height: 20)

    @Test func emptyProducesZeroSizeAndNoOrigins() {
        let result = FlowLayout.arrange([], spacing: 10, maxWidth: 500)
        #expect(result.origins.isEmpty)
        #expect(result.size == .zero)
    }

    @Test func itemsThatFitStayOnOneRow() {
        let result = FlowLayout.arrange([box, box, box], spacing: 10, maxWidth: 1000)
        #expect(result.origins == [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 110, y: 0),
            CGPoint(x: 220, y: 0)
        ])
        // Three 100-wide boxes with two 10-wide gaps between them.
        #expect(result.size == CGSize(width: 320, height: 20))
    }

    @Test func itemsWrapWhenTheRowIsTooNarrow() {
        let result = FlowLayout.arrange([box, box, box], spacing: 10, maxWidth: 250)
        #expect(result.origins == [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 110, y: 0),
            CGPoint(x: 0, y: 30)      // wrapped: previous row height 20 + spacing 10
        ])
        // Widest row is the first (two boxes = 210); height is two rows.
        #expect(result.size == CGSize(width: 210, height: 50))
    }
}
