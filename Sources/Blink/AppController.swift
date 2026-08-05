import SwiftUI
import BlinkCore

@MainActor
final class AppController: ObservableObject {
    @Published var nextBreakText: String = "--:--"
    @Published var todayText: String = "오늘: 0회 · 스킵 0"

    let engine: BreakEngine
    let statsStore: StatsStore
    private let clock = SystemClock()
    private var timer: Timer?
    private let overlay = OverlayController()

    init() {
        let config = AppController.loadConfig()
        engine = BreakEngine(config: config, clock: clock)
        statsStore = StatsStore(fileURL: AppController.statsURL(), now: clock.now)

        engine.onBreakCompleted = { [weak self] in
            self?.statsStore.recordCompleted(now: Date())
            self?.refresh()
        }
        engine.onBreakSkipped = { [weak self] in
            self?.statsStore.recordSkipped(now: Date())
            self?.refresh()
        }
        engine.onStateChange = { [weak self] state in
            self?.handleStateChange(state)
        }
        startTimer()
        refresh()
    }

    func breakNow() { engine.startBreakNow() }

    func quit() { NSApplication.shared.terminate(nil) }

    private func startTimer() {
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        engine.update()
        if let kind = engine.currentBreakKind(), case .onBreak = engine.state {
            overlay.updateCountdown(AppController.mmss(engine.phaseRemaining()), kind: kind, controller: self)
        }
        refresh()
    }

    private func handleStateChange(_ state: EngineState) {
        switch state {
        case .onBreak(let kind):
            overlay.show(kind: kind, controller: self)
        case .working, .paused, .preBreak:
            overlay.hide()
        }
    }

    private func refresh() {
        nextBreakText = AppController.mmss(engine.timeUntilNextBreak())
        let s = statsStore.today
        todayText = "오늘: \(s.breaksCompleted)회 · 스킵 \(s.breaksSkipped)"
    }

    // MARK: helpers

    static func mmss(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // 디버그: BLINK_FAST=1 이면 초 단위로 빠른 주기
    static func loadConfig() -> BreakConfig {
        if ProcessInfo.processInfo.environment["BLINK_FAST"] == "1" {
            return BreakConfig(
                shortInterval: 15, shortDuration: 5,
                longInterval: 40, longDuration: 10,
                preBreakWarning: 3, idleThreshold: 10, postponeInterval: 15
            )
        }
        return ConfigStore(defaults: .standard).load()   // Task 11
    }

    static func statsURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Blink/stats.json")
    }
}
