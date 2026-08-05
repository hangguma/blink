import SwiftUI

@main
struct BlinkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Blink", systemImage: "eye") {
            MenuContent(controller: delegate.controller)
        }
        .menuBarExtraStyle(.window)

        Settings {
            // Task 11에서 SettingsView로 교체
            Text("설정 (준비 중)").padding(40)
        }
    }
}
