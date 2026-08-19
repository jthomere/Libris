import Foundation
import AppKit
import CryptoKit

actor CoverImageCache {
    static let shared = CoverImageCache()

    private let memoryCache = NSCache<NSString, NSImage>()
    private var inFlight: [URL: Task<NSImage?, Never>] = [:]
    private var misses: Set<URL> = []
    private let diskCacheDirectory: URL

    private init() {
        memoryCache.countLimit = 200
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = caches.appending(component: "LibrisCovers", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    func image(for url: URL) async -> NSImage? {
        if misses.contains(url) { return nil }

        let key = url.absoluteString as NSString

        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        let fileURL = diskFileURL(for: url)
        if let data = try? Data(contentsOf: fileURL),
           let image = validImage(from: data) {
            memoryCache.setObject(image, forKey: key)
            return image
        }

        if let existing = inFlight[url] {
            return await existing.value
        }

        let task = Task<NSImage?, Never> {
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let image = validImage(from: data) else {
                return nil
            }
            try? data.write(to: fileURL, options: .atomic)
            return image
        }
        inFlight[url] = task
        let nsImage = await task.value
        inFlight.removeValue(forKey: url)
        if let nsImage {
            memoryCache.setObject(nsImage, forKey: key)
        } else if !Task.isCancelled {
            misses.insert(url)
        }
        return nsImage
    }

    private func diskFileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = hash.prefix(16).map { String(format: "%02x", $0) }.joined()
        return diskCacheDirectory.appending(component: name)
    }

    private func validImage(from data: Data) -> NSImage? {
        guard let image = NSImage(data: data),
              image.size.width > 10, image.size.height > 10 else { return nil }
        return image
    }
}
