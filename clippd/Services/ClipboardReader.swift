import UIKit
import SwiftData
import UniformTypeIdentifiers

enum PasteOutcome {
    case saved(ClipboardItem)
    case duplicate
    case empty
}

struct ClipboardReader {
    /// Handles the item providers delivered by a tapped `PasteButton`. Because the read is
    /// initiated by that system control, iOS does not show the "Allow Paste" prompt.
    static func handlePaste(providers: [NSItemProvider], context: ModelContext) async -> PasteOutcome {
        for provider in providers {
            if let url = await loadObject(NSURL.self, from: provider) as URL?, !url.isFileURL {
                let urlString = url.absoluteString
                guard !isDuplicateText(urlString, context: context) else { return .duplicate }
                let item = ClipboardItem(type: .link, urlString: urlString)
                context.insert(item)
                return .saved(item)
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
               let data = try? await loadImageData(from: provider) {
                guard let image = UIImage(data: data) else { continue }
                guard !isDuplicateImage(image, context: context) else { return .duplicate }
                let item = ClipboardItem(type: .image, imageData: data)
                context.insert(item)
                return .saved(item)
            }

            if let text = await loadObject(NSString.self, from: provider) as String?, !text.isEmpty {
                if looksLikeURL(text), let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    let urlString = url.absoluteString
                    guard !isDuplicateText(urlString, context: context) else { return .duplicate }
                    let item = ClipboardItem(type: .link, urlString: urlString)
                    context.insert(item)
                    return .saved(item)
                } else {
                    guard !isDuplicateText(text, context: context) else { return .duplicate }
                    let item = ClipboardItem(type: .text, textContent: text)
                    context.insert(item)
                    return .saved(item)
                }
            }
        }
        return .empty
    }

    /// Loads the copied value as an object (text, URL). Unlike `loadItem`, which often hands
    /// back raw Data for text, this always returns the decoded type — or nil if it isn't there.
    private static func loadObject<T: NSItemProviderReading>(_ type: T.Type, from provider: NSItemProvider) async -> T? {
        guard provider.canLoadObject(ofClass: type) else { return nil }
        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: type) { object, _ in
                continuation.resume(returning: object as? T)
            }
        }
    }

    private static func loadImageData(from provider: NSItemProvider) async throws -> Data? {
        let result: NSSecureCoding = try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, error in
                if let error { continuation.resume(throwing: error) }
                else if let item { continuation.resume(returning: item) }
                else { continuation.resume(throwing: NSError(domain: "ClippdPaste", code: 1)) }
            }
        }

        if let imageData = result as? Data {
            return compressedImageData(from: imageData)
        } else if let url = result as? URL, let data = try? Data(contentsOf: url) {
            return compressedImageData(from: data)
        } else if let image = result as? UIImage {
            return compressedImageData(image)
        }
        return nil
    }

    private static func isDuplicateText(_ text: String, context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<ClipboardItem>(
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

    private static func compressedImageData(from data: Data) -> Data {
        let maxBytes = 10 * 1024 * 1024
        if data.count <= maxBytes { return data }
        guard let image = UIImage(data: data) else { return data }
        return compressedImageData(image)
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
