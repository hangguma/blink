import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 메뉴바 전용 (Dock 아이콘 숨김)
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
