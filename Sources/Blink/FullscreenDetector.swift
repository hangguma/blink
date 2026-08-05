import AppKit
import CoreGraphics

enum FullscreenDetector {
    /// 최전면 앱의 창이 메인 화면을 꽉 채우는지(메뉴바 가림)로 판정하는 heuristic.
    /// 발표·전체화면 영상 감지용. 완벽하지 않으며 추후 정교화 여지 있음.
    static func isFullscreenActive() -> Bool {
        guard let main = NSScreen.main else { return false }
        let screenFrame = main.frame
        guard let front = NSWorkspace.shared.frontmostApplication else { return false }
        let pid = front.processIdentifier

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for info in infoList {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid,
                  let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let w = boundsDict["Width"], let h = boundsDict["Height"]
            else { continue }
            // 화면 크기와 거의 같으면 전체화면으로 간주 (2pt 여유)
            if abs(w - screenFrame.width) < 2, abs(h - screenFrame.height) < 2 {
                return true
            }
        }
        return false
    }
}
