import SwiftUI

struct ShareView: View {
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "clipboard.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                Text("Save to Clippd")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("This item will be saved to your clipboard history.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 48)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
