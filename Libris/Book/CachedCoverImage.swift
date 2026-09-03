import SwiftUI
import AppKit

struct CachedCoverImage: View {
    let url: URL
    var width: CGFloat = 60
    var height: CGFloat = 90

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary, lineWidth: 1))
            }
        }
        .task(id: url) {
            if let loaded = await CoverImageCache.shared.image(for: url) {
                guard !Task.isCancelled else { return }
                image = loaded
            }
        }
    }
}
