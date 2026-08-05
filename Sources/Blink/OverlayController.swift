import SwiftUI
import AppKit
import BlinkCore

@MainActor
final class OverlayController {
    private var panels: [NSPanel] = []
    private var countdownText = ""

    func show(kind: BreakKind, controller: AppController) {
        hide()
        let title = kind == .short ? "눈 휴식" : "긴 휴식"
        for screen in NSScreen.screens {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.ignoresMouseEvents = false
            panel.hasShadow = false

            let root = OverlayView(
                title: title,
                countdown: countdownText,
                onSkip: { [weak controller] in controller?.engine.skipCurrent() },
                onPostpone: { [weak controller] in controller?.engine.postponeCurrent() }
            )
            let host = NSHostingView(rootView: root)
            host.frame = CGRect(origin: .zero, size: screen.frame.size)
            panel.contentView = host
            panel.setFrame(screen.frame, display: true)
            panel.orderFrontRegardless()
            panels.append(panel)
        }
    }

    func updateCountdown(_ text: String, kind: BreakKind, controller: AppController) {
        countdownText = text
        let title = kind == .short ? "눈 휴식" : "긴 휴식"
        for panel in panels {
            let root = OverlayView(
                title: title,
                countdown: text,
                onSkip: { [weak controller] in controller?.engine.skipCurrent() },
                onPostpone: { [weak controller] in controller?.engine.postponeCurrent() }
            )
            (panel.contentView as? NSHostingView<OverlayView>)?.rootView = root
        }
    }

    func hide() {
        for panel in panels { panel.orderOut(nil) }
        panels.removeAll()
    }
}
