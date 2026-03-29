import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem

    var body: some View {
        HStack(spacing: 12) {
            typeIcon
                .font(.title3)
                .foregroundStyle(item.isPending ? .white : .secondary)
                .frame(width: 36, height: 36)
                .background(item.isPending ? Color.accentColor : Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                if item.isPending {
                    Text("New — tap to save")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }

                contentPreview
                    .lineLimit(2)

                Text(item.dateSaved, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            if item.type == .image, let data = item.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else if item.type == .link, let data = item.linkPreviewThumbnail, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(
            item.isPending
                ? Color.accentColor.opacity(0.08)
                : Color(.systemBackground)
        )
    }

    @ViewBuilder
    private var typeIcon: some View {
        switch item.type {
        case .text:
            Image(systemName: "doc.text")
        case .image:
            Image(systemName: "photo")
        case .link:
            Image(systemName: "link")
        }
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.type {
        case .text:
            Text(item.textContent ?? "")
                .font(.subheadline)

        case .image:
            Text("Image")
                .font(.subheadline)
                .foregroundStyle(.secondary)

        case .link:
            if let title = item.linkPreviewTitle, !title.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                    Text(item.urlString ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(item.urlString ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

#Preview {
    List {
        ClipboardItemRow(item: ClipboardItem(
            type: .text,
            textContent: "Hello, this is some sample copied text that might be long enough to clip.",
            isPending: true
        ))
        ClipboardItemRow(item: ClipboardItem(
            type: .text,
            textContent: "A previously saved text snippet."
        ))
        ClipboardItemRow(item: ClipboardItem(
            type: .link,
            urlString: "https://apple.com/swift"
        ))
        ClipboardItemRow(item: ClipboardItem(
            type: .link,
            urlString: "https://developer.apple.com",
            linkPreviewTitle: "Apple Developer"
        ))
        ClipboardItemRow(item: ClipboardItem(
            type: .image
        ))
    }
    .listStyle(.plain)
}
