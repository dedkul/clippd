import SwiftUI

struct OnboardingView: View {
    @AppStorage(AppSettings.Keys.hasSeenOnboarding, store: AppSettings.store)
    private var hasSeenOnboarding = AppSettings.Defaults.hasSeenOnboarding

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "clipboard.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 12) {
                Text("Never lose a copied item again")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Clippd saves things you copy — text, images, and links — so you can find them later. Open the app after copying, or use the share button from any app.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(Color.accentColor)
                Text("Everything stays on your device. Always.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button {
                withAnimation {
                    hasSeenOnboarding = true
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
