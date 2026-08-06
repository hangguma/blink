import SwiftUI

@main
struct BlinkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: delegate.controller)
        } label: {
            RingDotIcon()
                .frame(width: 18, height: 18)
                .foregroundStyle(.primary)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
