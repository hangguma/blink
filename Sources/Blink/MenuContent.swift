import SwiftUI

struct MenuContent: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RingDotIcon()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(BlinkTheme.sage)
                Text("다음 브레이크까지")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(controller.nextBreakText)
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
            }

            Text(controller.todayText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Divider()

            Button(action: { controller.breakNow() }) {
                Text("지금 쉬기").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(BlinkTheme.sage)

            HStack {
                SettingsLink { Text("설정…").font(.system(size: 12)) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("종료") { controller.quit() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 240)
    }
}
