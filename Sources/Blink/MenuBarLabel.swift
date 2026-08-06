import SwiftUI

/// 메뉴바 라벨 — 링 아이콘 + 다음 브레이크까지 남은 시간. 매초 갱신된다.
struct MenuBarLabel: View {
    @ObservedObject var controller: AppController

    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: BlinkTheme.menuBarIcon)
            Text(controller.nextBreakText)
                .monospacedDigit()
        }
    }
}
