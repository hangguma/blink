import SwiftUI

struct OverlayView: View {
    let title: String
    let countdown: String
    let onSkip: () -> Void
    let onPostpone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(title).font(.system(size: 34, weight: .semibold))
                Text("20피트(약 6m) 밖을 바라보세요").font(.title3).foregroundStyle(.secondary)
                Text(countdown).font(.system(size: 64, weight: .bold, design: .rounded)).monospacedDigit()
                HStack(spacing: 16) {
                    Button("미루기", action: onPostpone)
                    Button("건너뛰기", action: onSkip)
                }
                .controlSize(.large)
            }
            .foregroundStyle(.white)
        }
    }
}
