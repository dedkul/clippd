import LinkPresentation
import SwiftData
import UIKit

struct LinkPreviewFetcher {
    static func fetchIfNeeded(for item: ClipboardItem, context: ModelContext) {
        guard item.type == .link,
              item.linkPreviewTitle == nil,
              let urlString = item.urlString,
              let url = URL(string: urlString) else { return }

        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            guard let metadata, error == nil else { return }

            let title = metadata.title
            var thumbnailData: Data?

            if let imageProvider = metadata.imageProvider {
                imageProvider.loadObject(ofClass: UIImage.self) { image, _ in
                    if let uiImage = image as? UIImage {
                        thumbnailData = uiImage.jpegData(compressionQuality: 0.6)
                    }
                    DispatchQueue.main.async {
                        applyPreview(itemID: item.id, title: title, thumbnail: thumbnailData, context: context)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    applyPreview(itemID: item.id, title: title, thumbnail: nil, context: context)
                }
            }
        }
    }

    private static func applyPreview(itemID: UUID, title: String?, thumbnail: Data?, context: ModelContext) {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate<ClipboardItem> { $0.id == itemID }
        )
        guard let item = try? context.fetch(descriptor).first else { return }

        if let title, !title.isEmpty {
            item.linkPreviewTitle = title
        }
        if let thumbnail {
            item.linkPreviewThumbnail = thumbnail
        }
        try? context.save()
    }
}
