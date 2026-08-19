import SwiftUI
import AppKit

struct CachedCoverImage: View {
    let url: URL

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary, lineWidth: 1))
            }
        }
        .task(id: url) {
            if let loaded = await CoverImageCache.shared.image(for: url) {
                image = loaded
            }
        }
    }
}
