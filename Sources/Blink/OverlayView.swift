import SwiftUI

struct OverlayView: View {
    let title: String
    let countdown: String
    let onSkip: () -> Void
    let onPostpone: () -> Void

    var body: some View {
        ZStack {
            BlinkTheme.slate.ignoresSafeArea()
            VStack(spacing: 26) {
                RingDotIcon()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(BlinkTheme.sage.opacity(0.9))

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(BlinkTheme.mist)
                    Text("먼 곳을 바라보세요")
                        .font(.system(size: 15))
                        .foregroundStyle(BlinkTheme.mist.opacity(0.65))
                }

                Text(countdown)
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(BlinkTheme.sage)

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
                .font(.system(size: 14))
                .foregroundStyle(BlinkTheme.mist)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .overlay(Capsule().stroke(BlinkTheme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
