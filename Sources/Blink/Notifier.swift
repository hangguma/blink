import Foundation
import UserNotifications
import BlinkCore

@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let categoryId = "BLINK_BREAK"
    static let skipAction = "BLINK_SKIP"
    static let postponeAction = "BLINK_POSTPONE"

    weak var controller: AppController?
    private(set) var isAuthorized: Bool = false

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let skip = UNNotificationAction(identifier: Notifier.skipAction, title: "건너뛰기", options: [])
        let postpone = UNNotificationAction(identifier: Notifier.postponeAction, title: "미루기", options: [])
        let category = UNNotificationCategory(
            identifier: Notifier.categoryId,
            actions: [postpone, skip],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
        center.requestAuthorization(options: [.alert]) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
            }
        }
        center.getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = (settings.authorizationStatus == .authorized
                                      || settings.authorizationStatus == .provisional)
            }
        }
    }

    func notifyWarning(kind: BreakKind) {
        post(title: kind == .short ? "곧 눈 휴식" : "곧 긴 휴식",
             body: "잠시 후 브레이크가 시작됩니다.", id: "warning")
    }

    func notifyBreak(kind: BreakKind, remaining: TimeInterval) {
        let secs = Int(remaining.rounded())
        post(title: kind == .short ? "눈 휴식" : "긴 휴식",
             body: "20피트 밖을 \(secs)초간 바라보세요.", id: "break")
    }

    func clear() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    private func post(title: String, body: String, id: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = Notifier.categoryId
        let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    // 포그라운드에서도 배너 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case Notifier.skipAction: controller?.engine.skipCurrent()
        case Notifier.postponeAction: controller?.engine.postponeCurrent()
        default: break
        }
    }
}
