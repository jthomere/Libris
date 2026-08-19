import Foundation
import AppKit

actor CoverImageCache {
    static let shared = CoverImageCache()

    private let cache = NSCache<NSString, NSImage>()
    private var inFlight: [URL: Task<NSImage?, Never>] = [:]
    private var misses: Set<URL> = []

    private init() {
        cache.countLimit = 200
    }

    func image(for url: URL) async -> NSImage? {
        if misses.contains(url) { return nil }
        let key = url.absoluteString as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        if let existing = inFlight[url] {
            return await existing.value
        }
        let task = Task<NSImage?, Never> {
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200 else {
                return nil
            }
            guard let image = NSImage(data: data),
                  image.size.width > 10, image.size.height > 10 else { return nil }
            return image
        }
        inFlight[url] = task
        let nsImage = await task.value
        inFlight.removeValue(forKey: url)
        if let nsImage {
            cache.setObject(nsImage, forKey: key)
        } else {
            misses.insert(url)
        }
        return nsImage
    }
}
