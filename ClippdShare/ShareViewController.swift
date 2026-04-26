import UIKit
import SwiftData
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        saveAndDismiss()
    }

    private func saveAndDismiss() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            dismiss()
            return
        }

        let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.ashish.clippd")!
            .appending(path: "clippd.store")
        let config = ModelConfiguration(url: containerURL)
        guard let container = try? ModelContainer(for: ClipboardItem.self, configurations: config) else {
            dismiss()
            return
        }

        let context = ModelContext(container)

        Task {
            var saved = false

            for extensionItem in extensionItems {
                guard let attachments = extensionItem.attachments else { continue }

                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                       let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL,
                       !url.isFileURL {
                        context.insert(ClipboardItem(type: .link, urlString: url.absoluteString))
                        saved = true
                        continue
                    }

                    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
                       let data = try? await loadImageData(from: provider) {
                        context.insert(ClipboardItem(type: .image, imageData: data))
                        saved = true
                        continue
                    }

                    if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                       let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String,
                       !text.isEmpty {
                        if let url = Self.webURL(from: text) {
                            context.insert(ClipboardItem(type: .link, urlString: url.absoluteString))
                        } else {
                            context.insert(ClipboardItem(type: .text, textContent: text))
                        }
                        saved = true
                    }
                }
            }

            if saved {
                try? context.save()
                enforceHistoryLimit(context: context)
            }

            dismiss()
        }
    }

    private func loadImageData(from provider: NSItemProvider) async throws -> Data? {
        let result: NSSecureCoding = try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, error in
                if let error { continuation.resume(throwing: error) }
                else if let item { continuation.resume(returning: item) }
                else { continuation.resume(throwing: NSError(domain: "ClippdShare", code: 1)) }
            }
        }

        if let imageData = result as? Data {
            return compressIfNeeded(imageData)
        } else if let url = result as? URL, let data = try? Data(contentsOf: url) {
            return compressIfNeeded(data)
        } else if let image = result as? UIImage {
            return compressIfNeeded(image.pngData())
        }
        return nil
    }

    private func compressIfNeeded(_ data: Data?) -> Data? {
        guard let data else { return nil }
        let maxBytes = 10 * 1024 * 1024
        if data.count <= maxBytes { return data }
        guard let image = UIImage(data: data) else { return data }
        var quality: CGFloat = 0.8
        while quality > 0.1 {
            if let jpeg = image.jpegData(compressionQuality: quality), jpeg.count <= maxBytes {
                return jpeg
            }
            quality -= 0.1
        }
        return image.jpegData(compressionQuality: 0.1)
    }

    private func enforceHistoryLimit(context: ModelContext) {
        let limit = UserDefaults(suiteName: "group.com.ashish.clippd")?.integer(forKey: "historyLimit") ?? 20
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { !$0.isPending },
            sortBy: [SortDescriptor(\ClipboardItem.dateSaved, order: .reverse)]
        )
        guard let all = try? context.fetch(descriptor), all.count > limit else { return }
        for item in all.suffix(all.count - limit) {
            context.delete(item)
        }
        try? context.save()
    }

    private func dismiss() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private static func webURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains(" "),
              !trimmed.contains("\n"),
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host?.isEmpty == false else { return nil }
        return url
    }
}
