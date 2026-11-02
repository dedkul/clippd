#if DEBUG
import SwiftData
import UIKit

/// Debug-only: launch with `-seedSampleData` to fill the store with the clips used in the Figma designs.
enum SampleData {
    static func seedIfRequested(_ context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-seedSampleData") else { return }
        try? context.delete(model: ClipboardItem.self)
        let hour: TimeInterval = 3600
        let clips: [ClipboardItem] = [
            ClipboardItem(type: .text, textContent: "ashish@studio.com", dateSaved: .now - 48 * hour),
            ClipboardItem(type: .text, textContent: "BSB 062-000 · Acc 1234 5678 — for splitting bills", dateSaved: .now - 120 * hour),
            ClipboardItem(type: .link, urlString: "https://www.youtube.com/watch?v=Kp2B9xQ",
                          linkPreviewTitle: "How Apple designs for privacy — WWDC talk",
                          linkPreviewThumbnail: gradient(.systemPurple, .systemPink), dateSaved: .now - hour),
            ClipboardItem(type: .text, textContent: "#5E5CE6", dateSaved: .now - 2 * hour),
            ClipboardItem(type: .text, textContent: "Saturday: 12 King St. Ring the bell twice, we’re on level 3 — bring the speaker!", dateSaved: .now - 3 * hour),
            ClipboardItem(type: .link, urlString: "https://figma.com/design/pk6FCx",
                          linkPreviewTitle: "Clippd — Redesign",
                          linkPreviewThumbnail: gradient(.systemIndigo, .systemPink), dateSaved: .now - 4 * hour),
            ClipboardItem(type: .image, imageData: gradient(.systemTeal, .systemGreen), dateSaved: .now - 26 * hour),
            ClipboardItem(type: .text, textContent: "Flight QF 401 departs 7:15 am, gate 34", dateSaved: .now - 28 * hour),
        ]
        clips[0].isPinned = true
        clips[1].isPinned = true
        clips.forEach(context.insert)
        try? context.save()
    }

    private static func gradient(_ a: UIColor, _ b: UIColor) -> Data? {
        let size = CGSize(width: 240, height: 160)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [a.cgColor, b.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: nil)!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        }.jpegData(compressionQuality: 0.8)
    }
}
#endif
