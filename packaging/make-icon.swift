import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers

// Blink 앱 아이콘 생성기 — Horizon 팔레트 + Focus 링/닷.
// 사용법: swift make-icon.swift <출력 .iconset 디렉터리>

let slate = CGColor(red: 0x15 / 255.0, green: 0x18 / 255.0, blue: 0x1C / 255.0, alpha: 1)  // near-black tile
let sage  = CGColor(red: 0x2D / 255.0, green: 0xD4 / 255.0, blue: 0xBF / 255.0, alpha: 1)  // teal ring

func drawIcon(size: Int, to url: URL) {
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("context") }

    let f = CGFloat(size)

    // 라운드 사각 타일 (약간의 투명 여백 → macOS 스퀘어클 느낌)
    let inset = f * 0.08
    let rect = CGRect(x: inset, y: inset, width: f - 2 * inset, height: f - 2 * inset)
    let corner = rect.width * 0.225
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil))
    ctx.setFillColor(slate)
    ctx.fillPath()

    let cx = f / 2, cy = f / 2

    // 타이머 링 (한쪽 갭)
    ctx.setStrokeColor(sage)
    ctx.setLineWidth(rect.width * 0.06)
    ctx.setLineCap(.round)
    let ringR = rect.width * 0.28
    let start = CGFloat(150) * .pi / 180
    let end   = CGFloat(150 + 300) * .pi / 180
    ctx.addArc(center: CGPoint(x: cx, y: cy), radius: ringR, startAngle: start, endAngle: end, clockwise: false)
    ctx.strokePath()

    // 중심 닷
    ctx.setFillColor(sage)
    let dotR = rect.width * 0.058
    ctx.fillEllipse(in: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2))

    guard let img = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("image/dest") }
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("write \(url.path)") }
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <iconset-dir>\n".utf8))
    exit(2)
}
let dir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

let variants: [(Int, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]
for (px, name) in variants {
    drawIcon(size: px, to: dir.appendingPathComponent("\(name).png"))
}
print("wrote \(variants.count) png(s) to \(dir.path)")
