import UIKit
import SwiftData

struct ClipboardReader {
    static func readAndInsertPending(context: ModelContext) {
        removePendingItems(context: context)

        let pasteboard = UIPasteboard.general

        if pasteboard.hasImages, let image = pasteboard.image {
            guard !isDuplicateImage(image, context: context) else { return }
            let data = compressedImageData(image)
            let item = ClipboardItem(type: .image, imageData: data, isPending: true)
            context.insert(item)
        } else if pasteboard.hasURLs, let url = pasteboard.url {
            let urlString = url.absoluteString
            guard !isDuplicateText(urlString, context: context) else { return }
            let item = ClipboardItem(type: .link, urlString: urlString, isPending: true)
            context.insert(item)
        } else if pasteboard.hasStrings, let text = pasteboard.string, !text.isEmpty {
            if looksLikeURL(text), let url = URL(string: text) {
                let urlString = url.absoluteString
                guard !isDuplicateText(urlString, context: context) else { return }
                let item = ClipboardItem(type: .link, urlString: urlString, isPending: true)
                context.insert(item)
            } else {
                guard !isDuplicateText(text, context: context) else { return }
                let item = ClipboardItem(type: .text, textContent: text, isPending: true)
                context.insert(item)
            }
        }
    }

    private static func removePendingItems(context: ModelContext) {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.isPending }
        )
        if let pending = try? context.fetch(descriptor) {
            for item in pending {
                context.delete(item)
            }
        }
    }

    private static func isDuplicateText(_ text: String, context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { !$0.isPending },
            sortBy: [SortDescriptor(\ClipboardItem.dateSaved, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let latest = try? context.fetch(descriptor).first else { return false }

        switch latest.type {
        case .text:
            return latest.textContent == text
        case .link:
            return latest.urlString == text
        case .image:
            return false
        }
    }

    private static func isDuplicateImage(_ image: UIImage, context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { !$0.isPending },
            sortBy: [SortDescriptor(\ClipboardItem.dateSaved, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let latest = try? context.fetch(descriptor).first,
              latest.type == .image,
              let savedData = latest.imageData else { return false }

        let newData = compressedImageData(image)
        return savedData == newData
    }

    private static func compressedImageData(_ image: UIImage) -> Data {
        let maxBytes = 10 * 1024 * 1024
        if let png = image.pngData(), png.count <= maxBytes {
            return png
        }
        var quality: CGFloat = 0.8
        while quality > 0.1 {
            if let jpeg = image.jpegData(compressionQuality: quality), jpeg.count <= maxBytes {
                return jpeg
            }
            quality -= 0.1
        }
        return image.jpegData(compressionQuality: 0.1) ?? Data()
    }

    private static func looksLikeURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(" "), !trimmed.contains("\n") else { return false }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed) != nil
        }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        if let match = detector?.firstMatch(in: trimmed, range: range), match.range == range {
            return true
        }
        return false
    }
}
