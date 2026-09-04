import SwiftUI
import AppKit

struct CoverImageLoader<Content: View>: View {
    let url: URL?
    @ViewBuilder var content: (NSImage?) -> Content

    @State private var image: NSImage?

    var body: some View {
        content(image)
            .task(id: url) {
                image = nil
                guard let url else { return }
                if let loaded = await CoverImageCache.shared.image(for: url) {
                    guard !Task.isCancelled else { return }
                    image = loaded
                }
            }
    }
}
