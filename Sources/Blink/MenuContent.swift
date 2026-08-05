import SwiftUI

struct MenuContent: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("다음 브레이크까지  \(controller.nextBreakText)")
                .font(.headline)
            Text(controller.todayText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Divider()
            Button("지금 쉬기") { controller.breakNow() }
            SettingsLink { Text("설정…") }   // macOS 14+
            Divider()
            Button("종료") { controller.quit() }
        }
        .padding(12)
        .frame(width: 240)
    }
}
