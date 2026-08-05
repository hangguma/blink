import Foundation

public final class StatsStore {
    private let fileURL: URL
    private let calendar: Calendar
    public private(set) var today: DayStats

    public init(fileURL: URL, now: Date, calendar: Calendar = .current) {
        self.fileURL = fileURL
        self.calendar = calendar
        let key = StatsStore.dateKey(for: now, calendar: calendar)
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(DayStats.self, from: data),
           saved.date == key {
            self.today = saved
        } else {
            self.today = DayStats(date: key)
        }
    }

    public func recordCompleted(now: Date) {
        rollover(now)
        today.breaksCompleted += 1
        save()
    }

    public func recordSkipped(now: Date) {
        rollover(now)
        today.breaksSkipped += 1
        save()
    }

    public static func dateKey(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func rollover(_ now: Date) {
        let key = StatsStore.dateKey(for: now, calendar: calendar)
        if today.date != key {
            today = DayStats(date: key)
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(today)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // 통계는 부가기능 — 저장 실패는 조용히 무시 (앱 동작 안 막음)
        }
    }
}
