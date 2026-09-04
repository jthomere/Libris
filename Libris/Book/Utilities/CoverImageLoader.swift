import SwiftUI
import AppKit

/// Loads a cover image from `CoverImageCache` for `url` and hands the result to
/// `content`, reloading when `url` changes and dropping a late result if the
/// load was cancelled (e.g. the cell was reused). Shared by the fixed-size
/// `CachedCoverImage` and the mini tile's cover, so both stay in sync.
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
