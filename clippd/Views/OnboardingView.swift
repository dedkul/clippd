import SwiftUI
import TipKit

/// First-launch welcome sheet, in the style of Apple's own "Welcome to Notes".
struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(.tint, in: .rect(cornerRadius: 18))
                        .padding(.bottom, 12)
                        .accessibilityHidden(true)

                    Text("Welcome to Clippd")
                        .font(.largeTitle.bold())
                    Text("The clipboard history iOS doesn’t have.")
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 32)

                    VStack(alignment: .leading, spacing: 24) {
                        feature("doc.on.clipboard", "Tap Paste to save",
                                "Copy anything in any app, then tap Paste in Clippd. That one tap is your permission.")
                        feature("square.and.arrow.up", "Save from the Share menu",
                                "In Safari, Photos and more, tap Share › Clippd. No need to open the app.")
                        feature("lock.fill", "Stays on this iPhone",
                                "No account, no cloud. Clippd never reads your clipboard on its own.")
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 56)
            }

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled()
    }

    private func feature(_ symbol: String, _ title: String, _ message: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)
        }
    }
}

/// One tip, shown once, pointing at Paste on the empty first-launch screen.
struct PasteTip: Tip {
    var title: Text { Text("Save what you copied") }
    var message: Text? { Text("Tap Paste. iOS won’t ask for permission — tapping this button is the permission.") }
    var image: Image? { Image(systemName: "doc.on.clipboard") }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        OnboardingView {}
    }
}
