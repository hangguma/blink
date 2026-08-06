import SwiftUI

struct OverlayView: View {
    let title: String
    let countdown: String
    let onSkip: () -> Void
    let onPostpone: () -> Void

    var body: some View {
        ZStack {
            BlinkTheme.bg.ignoresSafeArea()
            VStack(spacing: 24) {
                RingDotIcon()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(BlinkTheme.accent)

                Text("\(title) · 먼 곳을 보기")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(BlinkTheme.muted)

                Text(countdown)
                    .font(.system(size: 76, weight: .light, design: .monospaced))
                    .foregroundStyle(BlinkTheme.accent)

                HStack(spacing: 12) {
                    OverlayPill(label: "미루기", action: onPostpone)
                    OverlayPill(label: "건너뛰기", action: onSkip)
                }
            }
        }
    }
}

private struct OverlayPill: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(BlinkTheme.muted)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .overlay(Capsule().stroke(BlinkTheme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
