import SwiftUI

struct CachedCoverImage: View {
    let url: URL
    var width: CGFloat = 60
    var height: CGFloat = 90

    var body: some View {
        CoverImageLoader(url: url) { image in
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary, lineWidth: 1))
            }
        }
    }
}
