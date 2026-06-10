import SwiftUI

/// First-run primer explaining what Hush uses and that everything stays on device.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Welcome to Hush")
                .font(.title.weight(.semibold))
            Text("An invisible teleprompter that lives in your notch. Everything runs on your Mac.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 14) {
                row("mic", "Microphone & Speech", "Follow your voice and show live captions, on device.")
                row("camera", "Camera", "Hand-gesture control and recording takes.")
                row("lock", "Private", "No account, no cloud, no data leaves your Mac.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Get Started", action: onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(32)
        .frame(width: 420)
    }

    private func row(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
