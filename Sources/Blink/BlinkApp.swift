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
            SettingsView()
        }
    }
}
