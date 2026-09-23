// Renders the 1024x1024 App Store in-app purchase promotional image (no alpha, per App Store Connect).
// Run: swift Tools/promo-image.swift vipm-premium-promo.png
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "vipm-premium-promo.png"

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255, alpha: 1)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                          bytesPerRow: 0, space: space,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("context")
}

// Background: same navy radial gradient as PracticeExamView.
let bg = CGGradient(colorsSpace: space, colors: [rgb(0x1C3350), rgb(0x101D2E)] as CFArray,
                    locations: [0, 1])!
ctx.drawRadialGradient(bg, startCenter: CGPoint(x: size / 2, y: size), startRadius: 0,
                       endCenter: CGPoint(x: size / 2, y: size), endRadius: size,
                       options: .drawsAfterEndLocation)

// Amber badge with star, matching the premium card.
let badge = CGRect(x: 312, y: 452, width: 400, height: 400)
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: badge, cornerWidth: 104, cornerHeight: 104, transform: nil))
ctx.clip()
let amber = CGGradient(colorsSpace: space, colors: [rgb(0xFBBF57), rgb(0xF59E0B)] as CFArray,
                       locations: [0, 1])!
ctx.drawLinearGradient(amber, start: CGPoint(x: badge.minX, y: badge.maxY),
                       end: CGPoint(x: badge.maxX, y: badge.minY), options: [])
ctx.restoreGState()

func draw(_ text: String, size fontSize: Double, weight: CGFloat, color: CGColor, centerY: Double) {
    let font = CTFontCreateWithFontDescriptor(
        CTFontDescriptorCreateWithAttributes([
            kCTFontFamilyNameAttribute: "Helvetica Neue",
            kCTFontTraitsAttribute: [kCTFontWeightTrait: weight],
        ] as CFDictionary), fontSize, nil)
    let attributed = NSAttributedString(string: text, attributes: [
        .init(kCTFontAttributeName as String): font,
        .init(kCTForegroundColorAttributeName as String): color,
        .init(kCTKernAttributeName as String): fontSize * 0.02,
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.textPosition = CGPoint(x: (size - bounds.width) / 2 - bounds.minX,
                               y: centerY - bounds.height / 2 - bounds.minY)
    CTLineDraw(line, ctx)
}

draw("\u{2605}", size: 220, weight: 0.2, color: rgb(0x1B1300), centerY: 652)
draw("PSPO I Prep", size: 104, weight: 0.6, color: rgb(0xE4ECF5), centerY: 320)
draw("Premium Lifetime Access", size: 52, weight: 0.3, color: rgb(0xFBBF57), centerY: 216)

let url = URL(fileURLWithPath: out) as CFURL
guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("destination")
}
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
precondition(CGImageDestinationFinalize(dest), "write failed")
print("wrote \(out)")
