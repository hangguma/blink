import SwiftUI
import AppKit

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Focus 팔레트 — 선명·프로 (니어블랙 + 틸, 모노 타이포).
enum BlinkTheme {
    static let bg = Color(hex: 0x0E1013)         // 오버레이 배경 (near-black)
    static let accent = Color(hex: 0x2DD4BF)     // 틸 액센트 (카운트다운·버튼·아이콘)
    static let accentInk = Color(hex: 0x0B4A43)  // 틸 위 텍스트
    static let muted = Color(hex: 0x9AA8A6)      // 어두운 배경 위 흐린 텍스트
    static let hairline = Color(hex: 0x2C3438)   // 얇은 경계
}

extension BlinkTheme {
    /// 메뉴바용 템플릿 이미지 (링+닷). 검정으로 그리고 isTemplate = true 이면
    /// macOS가 메뉴바 라이트/다크에 맞춰 자동으로 색을 입힌다. 해상도 독립적으로
    /// 재렌더되므로 retina에서도 또렷하다.
    static let menuBarIcon: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let cx = rect.midX, cy = rect.midY
            let radius = rect.width * 0.34
            NSColor.black.set()

            let ring = NSBezierPath()
            ring.appendArc(
                withCenter: NSPoint(x: cx, y: cy),
                radius: radius, startAngle: 125, endAngle: 125 + 300
            )
            ring.lineWidth = rect.width * 0.11
            ring.lineCapStyle = .round
            ring.stroke()

            let dotR = rect.width * 0.11
            NSBezierPath(ovalIn: NSRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)).fill()
            return true
        }
        image.isTemplate = true
        return image
    }()
}

/// Focus 링+닷 아이콘 — 프레임 크기에 비례해 그려진다. 색은 부모의 foregroundStyle을 따른다.
/// (오버레이·메뉴 팝업 등 앱 내부 SwiftUI 용. 메뉴바는 BlinkTheme.menuBarIcon 사용.)
struct RingDotIcon: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .trim(from: 0.07, to: 0.93)
                    .stroke(style: StrokeStyle(lineWidth: s * 0.12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .frame(width: s * 0.20, height: s * 0.20)
            }
            .frame(width: s, height: s)
        }
    }
}
