import SwiftUI
internal import Combine

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

                RelativeTimeView(date: item.dateSaved)
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
                ? Color.accentColor.opacity(0.12)
                : nil
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

struct RelativeTimeView: View {
    let date: Date
    @State private var timeString: String = ""
    
    // Timer that fires every 60 seconds
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(timeString)
            .onAppear { updateTimeString() }
            .onReceive(timer) { _ in updateTimeString() }
    }
    
    private func updateTimeString() {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        if diff < 60 {
            timeString = "Just now"
        } else if diff < 3600 {
            let minutes = Int(diff / 60)
            timeString = "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            timeString = "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if diff < 604800 {
            let days = Int(diff / 86400)
            timeString = "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            timeString = formatter.string(from: date)
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
