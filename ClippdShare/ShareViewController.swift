import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private var modelContainer: ModelContainer?

    override func viewDidLoad() {
        super.viewDidLoad()

        let schema = Schema([ClipboardItem.self])
        let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ashish.clippd"
        )!
        let storeURL = groupURL.appendingPathComponent("clippd.store")
        let config = ModelConfiguration("Clippd", url: storeURL)
        modelContainer = try? ModelContainer(for: schema, configurations: [config])

        let shareView = ShareView(
            onSave: { [weak self] in self?.saveSharedItem() },
            onCancel: { [weak self] in self?.cancel() }
        )
        let hostingController = UIHostingController(rootView: shareView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
    }

    private func saveSharedItem() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem],
              let container = modelContainer else {
            showError()
            return
        }

        let context = ModelContext(container)

        Task {
            var saved = false

            for extensionItem in extensionItems {
                guard let attachments = extensionItem.attachments else { continue }

                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                            let item = ClipboardItem(type: .link, urlString: url.absoluteString)
                            context.insert(item)
                            saved = true
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        if let data = try? await loadImageData(from: provider) {
                            let item = ClipboardItem(type: .image, imageData: data)
                            context.insert(item)
                            saved = true
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String,
                           !text.isEmpty {
                            let item = ClipboardItem(type: .text, textContent: text)
                            context.insert(item)
                            saved = true
                        }
                    }

                    if saved { break }
                }
                if saved { break }
            }

            if saved {
                try? context.save()
                enforceHistoryLimit(context: context)
                extensionContext?.completeRequest(returningItems: nil)
            } else {
                showError()
            }
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

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "ClippdShare", code: 0))
    }

    private func showError() {
        let alert = UIAlertController(
            title: "Error",
            message: "Could not save. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.cancel()
        })
        present(alert, animated: true)
    }
}
