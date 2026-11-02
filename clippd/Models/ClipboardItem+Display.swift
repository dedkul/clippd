import SwiftUI
import UIKit

/// How a clip presents itself in the list, board and filters.
/// Derived from stored fields only, so the share extension's copy of the model stays untouched.
extension ClipboardItem {
    enum Kind {
        case text, link, youTube, color, image
    }

    var kind: Kind {
        switch type {
        case .image: return .image
        case .link: return isYouTube ? .youTube : .link
        case .text: return hexColor == nil ? .text : .color
        }
    }

    var host: String? {
        guard let urlString, let host = URL(string: urlString)?.host() else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    var isYouTube: Bool {
        guard let host else { return false }
        return host == "youtu.be" || host.hasSuffix("youtube.com")
    }

    /// A clip that is only a hex colour, like "#5E5CE6" or "5e5ce6".
    var hexColor: Color? {
        guard let text = textContent?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        var hex = text.hasPrefix("#") ? String(text.dropFirst()) : text
        if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var title: String {
        switch kind {
        case .text:
            return textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        case .color:
            return textContent?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        case .image:
            return "Image"
        case .link, .youTube:
            if let title = linkPreviewTitle, !title.isEmpty { return title }
            return urlString?.replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "") ?? ""
        }
    }

    /// "Text", "youtube.com", "Image · 1.2 MB" — the part before the time.
    var detail: String {
        switch kind {
        case .text: return "Text"
        case .color: return "Color"
        case .image:
            guard let imageData else { return "Image" }
            return "Image · " + ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file)
        case .link, .youTube:
            return linkPreviewTitle == nil ? "Link" : (host ?? "Link")
        }
    }

    var thumbnail: UIImage? {
        switch type {
        case .image: return imageData.flatMap(UIImage.init(data:))
        case .link: return linkPreviewThumbnail.flatMap(UIImage.init(data:))
        case .text: return nil
        }
    }
}

extension Date {
    /// Compact age for list rows: "Now", "5m", "3h", "2d", then "Oct 28".
    func shortAge(now: Date = .now) -> String {
        let seconds = now.timeIntervalSince(self)
        switch seconds {
        case ..<60: return "Now"
        case ..<3600: return "\(Int(seconds / 60))m"
        case ..<86_400: return "\(Int(seconds / 3600))h"
        case ..<604_800: return "\(Int(seconds / 86_400))d"
        default: return formatted(.dateTime.month(.abbreviated).day())
        }
    }
}
