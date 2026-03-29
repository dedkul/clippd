import Foundation
import SwiftData

enum ClipboardItemType: String, Codable, CaseIterable {
    case text
    case image
    case link
}

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var type: ClipboardItemType
    var textContent: String?
    @Attribute(.externalStorage) var imageData: Data?
    var urlString: String?
    var linkPreviewTitle: String?
    @Attribute(.externalStorage) var linkPreviewThumbnail: Data?
    var dateSaved: Date
    var isPending: Bool

    init(
        type: ClipboardItemType,
        textContent: String? = nil,
        imageData: Data? = nil,
        urlString: String? = nil,
        linkPreviewTitle: String? = nil,
        linkPreviewThumbnail: Data? = nil,
        dateSaved: Date = .now,
        isPending: Bool = false
    ) {
        self.id = UUID()
        self.type = type
        self.textContent = textContent
        self.imageData = imageData
        self.urlString = urlString
        self.linkPreviewTitle = linkPreviewTitle
        self.linkPreviewThumbnail = linkPreviewThumbnail
        self.dateSaved = dateSaved
        self.isPending = isPending
    }
}
