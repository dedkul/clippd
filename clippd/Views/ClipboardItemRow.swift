import SwiftUI

/// The 36pt square in front of every row: the clip itself when it can show
/// itself (image, colour, link preview), a quiet grey glyph otherwise.
struct ClipThumbnail: View {
    let item: ClipboardItem
    var size: CGFloat = 36

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: 8))
    }

    @ViewBuilder
    private var content: some View {
        if let image = item.thumbnail {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let color = item.hexColor {
            color
        } else {
            Image(systemName: item.type == .link ? "link" : "text.alignleft")
                .font(.body)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.fill.tertiary)
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem

    var body: some View {
        HStack(spacing: 12) {
            ClipThumbnail(item: item)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                TimelineView(.everyMinute) { context in
                    Text("\(item.detail) · \(item.dateSaved.shortAge(now: context.date))")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A Board tile. Visual clips (colours, images, previews) get space to show themselves.
struct ClipCard: View {
    let item: ClipboardItem

    var body: some View {
        if let color = item.hexColor {
            VStack(alignment: .leading, spacing: 2) {
                Spacer(minLength: 40)
                Text("Color").font(.caption)
                Text(item.title).font(.title2.bold())
            }
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: .rect(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if let image = item.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 140)
                        .clipShape(.rect(cornerRadius: 10))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.isPinned ? "Pinned" : item.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.title)
                        .font(.subheadline)
                        .lineLimit(3)
                }
            }
            .padding(item.thumbnail == nil ? 12 : 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        }
    }
}

#Preview {
    List {
        ClipboardItemRow(item: ClipboardItem(type: .text, textContent: "Flight QF 401 departs 7:15 am, gate 34"))
        ClipboardItemRow(item: ClipboardItem(type: .text, textContent: "#5E5CE6"))
        ClipboardItemRow(item: ClipboardItem(type: .link, urlString: "https://figma.com/design/pk6F"))
        ClipboardItemRow(item: ClipboardItem(type: .link, urlString: "https://youtube.com/watch?v=1", linkPreviewTitle: "How Apple designs for privacy"))
    }
}
