import SwiftUI

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

/// Horizon 팔레트 — 차분·미니멀 (슬레이트 + 세이지).
enum BlinkTheme {
    static let slate = Color(hex: 0x233047)     // 오버레이 배경
    static let sage = Color(hex: 0x86B8A9)      // 액센트 (카운트다운·버튼·아이콘)
    static let sageInk = Color(hex: 0x1E3229)   // 세이지 위 텍스트
    static let mist = Color(hex: 0xAEBCCB)      // 슬레이트 위 흐린 텍스트
    static let hairline = Color(hex: 0x4A5D78)  // 슬레이트 위 얇은 경계
}

/// Focus 링+닷 아이콘 — 프레임 크기에 비례해 그려진다. 색은 부모의 foregroundStyle을 따른다.
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
